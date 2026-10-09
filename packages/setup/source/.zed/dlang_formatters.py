"""LLDB formatters for D. Filename must stay dlang_formatters.py."""

import lldb

MAX_CHILDREN = 10000
MAX_AA = 256
MAX_STRING = 256
EXPAND_STRINGS = False
HASH_EMPTY, HASH_DELETED = 0, 1
CHAR_TYPES = {
    "char": "utf-8", "char8_t": "utf-8",
    "wchar": "utf-16-le", "wchar_t": "utf-16-le", "char16_t": "utf-16-le",
    "dchar": "utf-32-le", "char32_t": "utf-32-le",
}
_QUALS = ("const", "immutable", "inout", "shared")


def _ptr_size(process):
    return process.GetAddressByteSize() or 8


def _read_uint(process, addr, size):
    err = lldb.SBError()
    val = process.ReadUnsignedFromMemory(addr, size, err)
    return None if err.Fail() else val


def _unqual_name(sbtype):
    try:
        return sbtype.GetUnqualifiedType().GetName() or ""
    except Exception:
        return ""


def _strip_qualifiers(name):
    name = (name or "").strip()
    changed = True
    while changed:
        changed = False
        for q in _QUALS:
            prefix = q + "("
            if not (name.startswith(prefix) and name.endswith(")")):
                continue
            depth = 0
            wraps = False
            for i, c in enumerate(name):
                depth += (c == "(") - (c == ")")
                if depth == 0:
                    wraps = i == len(name) - 1 and i >= len(prefix) - 1
                    break
            if wraps:
                name = name[len(prefix):-1].strip()
                changed = True
                break
    return name


def _is_char(sbtype):
    return _strip_qualifiers(_unqual_name(sbtype)) in CHAR_TYPES


def _as_number_if_byte(child, elem):
    name = _strip_qualifiers(_unqual_name(elem))
    if name in ("byte", "ubyte", "unsigned char", "signed char"):
        child.SetFormat(lldb.eFormatDecimal)
    return child


def _escape(text):
    return text.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t")


def _decode(process, ptr, length, elem):
    enc = CHAR_TYPES.get(_strip_qualifiers(_unqual_name(elem)))
    size = elem.GetByteSize()
    if enc is None or length == 0 or ptr == 0 or size <= 0:
        return None
    n = min(length, MAX_STRING)
    err = lldb.SBError()
    data = process.ReadMemory(ptr, n * size, err)
    if err.Fail() or data is None:
        return "<unreadable>"
    text = _escape(bytes(data).decode(enc, errors="replace"))
    return '"%s"%s' % (text, "..." if length > n else "")


def _slice_parts(valobj):
    v = valobj.GetNonSyntheticValue()
    length_obj = v.GetChildMemberWithName("length")
    ptr_obj = v.GetChildMemberWithName("ptr")
    if not (length_obj.IsValid() and ptr_obj.IsValid()):
        return None
    return length_obj.GetValueAsUnsigned(0), ptr_obj.GetValueAsUnsigned(0), ptr_obj.GetType().GetPointeeType()


def _child_index(name):
    try:
        return int(name.strip("[]"))
    except ValueError:
        return -1


class DSliceSyntheticProvider:
    def __init__(self, valobj, internal_dict):
        self.valobj = valobj
        self.update()

    def update(self):
        self.length = self.ptr_addr = self.element_size = 0
        self.element_type = None
        try:
            parts = _slice_parts(self.valobj)
            if parts is None:
                return True
            length, ptr, elem = parts
            self.ptr_addr, self.element_type, self.element_size = ptr, elem, elem.GetByteSize()
            if (not EXPAND_STRINGS and _is_char(elem)) or ptr == 0 or self.element_size == 0:
                return True
            self.length = min(length, MAX_CHILDREN)
        except Exception:
            self.length = 0
        return True

    def has_children(self):
        return self.length > 0

    def num_children(self):
        return self.length

    def get_child_at_index(self, index):
        if index < 0 or index >= self.length or self.element_type is None:
            return None
        return _as_number_if_byte(
            self.valobj.CreateValueFromAddress("[%d]" % index, self.ptr_addr + index * self.element_size, self.element_type),
            self.element_type,
        )

    def get_child_index(self, name):
        return _child_index(name)


def d_slice_summary(valobj, internal_dict):
    try:
        parts = _slice_parts(valobj)
        if parts is None:
            return None
        length, ptr, elem = parts
        return _decode(valobj.GetProcess(), ptr, length, elem) or "length %d" % length
    except Exception:
        return "<error>"


def _split_aa(type_name):
    type_name = _strip_qualifiers(type_name)
    if not type_name or not type_name.endswith("]"):
        return None
    depth = 0
    for i in range(len(type_name) - 1, -1, -1):
        depth += (type_name[i] == "]") - (type_name[i] == "[")
        if type_name[i] == "[" and depth == 0:
            key, val = type_name[i + 1:-1].strip(), type_name[:i].strip()
            if not key or not val or key.isdigit():
                return None
            return val, key
    return None


def _find_type(target, name):
    if not name:
        return None
    t = target.FindFirstType(name)
    if t.IsValid():
        return t
    bare = _strip_qualifiers(name)
    if bare != name:
        t = target.FindFirstType(bare)
        if t.IsValid():
            return t
    aliases = {
        "string": ("immutable(char)[]", "const(char)[]", "char[]"),
        "wstring": ("immutable(wchar)[]", "const(wchar)[]", "wchar[]"),
        "dstring": ("immutable(dchar)[]", "const(dchar)[]", "dchar[]"),
    }
    for alt in aliases.get(name, ()):
        t = target.FindFirstType(alt)
        if t.IsValid():
            return t
    return None


def _aa_impl_layout(ps):
    used = 2 * ps
    deleted = used + 4
    entry = (deleted + 4 + ps - 1) & ~(ps - 1)
    first = entry + ps
    return {
        "buckets_len": 0, "buckets_ptr": ps, "used": used, "deleted": deleted,
        "first": first, "keysz": first + 4, "valsz": first + 8, "valoff": first + 12,
        "bucket": 2 * ps,
    }


def _aa_impl(valobj):
    v = valobj.GetNonSyntheticValue()
    impl = v.GetChildMemberWithName("impl")
    if not impl.IsValid() and v.GetNumChildren() == 1:
        impl = v.GetChildAtIndex(0)
    return v, impl


class DAssocArraySyntheticProvider:
    def __init__(self, valobj, internal_dict):
        self.valobj = valobj
        self.entries = []
        self.update()

    def update(self):
        self.entries, self.count, self.bad = [], 0, False
        try:
            v, impl = _aa_impl(self.valobj)
            if not impl.IsValid():
                return True
            impl_addr = impl.GetValueAsUnsigned(0)
            if impl_addr == 0:
                return True
            process, ps = v.GetProcess(), _ptr_size(v.GetProcess())
            off = _aa_impl_layout(ps)
            fields = [off[k] for k in ("buckets_len", "buckets_ptr", "used", "deleted", "first", "keysz", "valsz", "valoff")]
            sizes = [ps, ps, 4, 4, 4, 4, 4, 4]
            vals = [_read_uint(process, impl_addr + o, n) for o, n in zip(fields, sizes)]
            if None in vals:
                self.bad = True
                return True
            buckets_len, buckets_ptr, used, deleted, first, keysz, valsz, valoff = vals
            if deleted > used or used > 10_000_000 or first > buckets_len or max(keysz, valsz, valoff) > 1_048_576:
                self.bad = True
                return True
            self.count = used - deleted
            if buckets_ptr == 0 or self.count == 0:
                return True
            split = _split_aa(v.GetType().GetUnqualifiedType().GetName() or "")
            target = v.GetTarget()
            key_type = _find_type(target, split[1]) if split else None
            val_type = _find_type(target, split[0]) if split else None
            high, bsz, shown = 1 << (ps * 8 - 1), off["bucket"], 0
            for i in range(first, buckets_len):
                if shown >= MAX_AA:
                    break
                base = buckets_ptr + i * bsz
                h, entry = _read_uint(process, base, ps), _read_uint(process, base + ps, ps)
                if h is None or entry is None or entry == 0 or h in (HASH_EMPTY, HASH_DELETED) or (h & high) == 0:
                    continue
                self.entries.append((self._key_name(process, entry, key_type, shown), entry + valoff, val_type))
                shown += 1
        except Exception:
            self.bad, self.entries = True, []
        return True

    def _key_name(self, process, entry, key_type, index):
        text = None
        if key_type is not None:
            probe = self.valobj.CreateValueFromAddress("_k", entry, key_type)
            parts = _slice_parts(probe)
            text = _decode(process, parts[1], parts[0], parts[2]) if parts else (probe.GetValue() or probe.GetSummary())
        text = (text or "%d" % index).replace("\n", " ")
        return "[%s]" % (text[:77] + "..." if len(text) > 80 else text)

    def has_children(self):
        return bool(self.entries)

    def num_children(self):
        return len(self.entries)

    def get_child_at_index(self, index):
        if index < 0 or index >= len(self.entries):
            return None
        name, addr, val_type = self.entries[index]
        if val_type is not None and val_type.IsValid():
            return self.valobj.CreateValueFromAddress(name, addr, val_type)
        voidp = self.valobj.GetTarget().FindFirstType("void").GetPointerType()
        return self.valobj.CreateValueFromAddress(name, addr, voidp) if voidp.IsValid() else None

    def get_child_index(self, name):
        for i, entry in enumerate(self.entries):
            if entry[0] == name:
                return i
        return -1


def d_aa_summary(valobj, internal_dict):
    try:
        v, impl = _aa_impl(valobj)
        if not impl.IsValid():
            return None
        impl_addr = impl.GetValueAsUnsigned(0)
        if impl_addr == 0:
            return "null"
        process, ps = v.GetProcess(), _ptr_size(v.GetProcess())
        off = _aa_impl_layout(ps)
        used = _read_uint(process, impl_addr + off["used"], 4)
        deleted = _read_uint(process, impl_addr + off["deleted"], 4)
        if used is None or deleted is None or deleted > used or used > 10_000_000:
            return "<unrecognized AA>"
        extra = ", showing %d" % MAX_AA if used - deleted > MAX_AA else ""
        return "length %d%s" % (used - deleted, extra)
    except Exception:
        return "<error>"


def d_static_summary(valobj, internal_dict):
    return ""


class DStaticArraySyntheticProvider:
    def __init__(self, valobj, internal_dict):
        self.valobj = valobj
        self.update()

    def update(self):
        self.count = self.elem_size = 0
        self.elem = None
        try:
            v = self.valobj.GetNonSyntheticValue()
            elem = v.GetType().GetArrayElementType()
            if not elem.IsValid():
                return True
            n, es = v.GetNumChildren(), elem.GetByteSize()
            if n == 0 and es:
                n = v.GetType().GetByteSize() // es
            self.elem, self.elem_size, self.count = elem, es, min(n, MAX_CHILDREN)
        except Exception:
            self.count = 0
        return True

    def has_children(self):
        return self.count > 0

    def num_children(self):
        return self.count

    def get_child_at_index(self, index):
        if index < 0 or index >= self.count or not self.elem_size:
            return None
        return _as_number_if_byte(
            self.valobj.GetNonSyntheticValue().CreateChildAtOffset("[%d]" % index, index * self.elem_size, self.elem),
            self.elem,
        )

    def get_child_index(self, name):
        return _child_index(name)


def _is_int8(t):
    name = _strip_qualifiers(_unqual_name(t))
    if name in CHAR_TYPES or name == "bool":
        return False
    if name in ("byte", "ubyte", "signed char", "unsigned char"):
        return True
    try:
        if t.GetTypeClass() == lldb.eTypeClassEnumeration and t.GetByteSize() == 1:
            return True
    except Exception:
        pass
    return False


def _fmt_int8(v):
    name = _strip_qualifiers(_unqual_name(v.GetType()))
    if name in ("byte", "signed char"):
        return str(v.GetValueAsSigned(0))
    return str(v.GetValueAsUnsigned(0))


def d_int8_summary(valobj, internal_dict):
    v = valobj.GetNonSyntheticValue()
    if _is_int8(v.GetType()):
        return _fmt_int8(v)
    return v.GetValue() or ""


def d_delegate_summary(valobj, internal_dict):
    try:
        v = valobj.GetNonSyntheticValue()
        ctx, fn = v.GetChildMemberWithName("ptr"), v.GetChildMemberWithName("funcptr")
        if not (ctx.IsValid() and fn.IsValid()):
            return None
        c, f = ctx.GetValueAsUnsigned(0), fn.GetValueAsUnsigned(0)
        return "null" if c == 0 and f == 0 else "context = 0x%x, func = 0x%x" % (c, f)
    except Exception:
        return "<error>"


def dlang_status(debugger, command, result, internal_dict):
    result.AppendMessage("dlang formatters loaded (category 'dlang'): slices, static arrays, strings, associative arrays, delegates")
    result.AppendMessage("check with: type summary list, type synthetic list")


def _add(debugger, kind, regex, spec):
    debugger.HandleCommand('type %s add -w dlang -x "%s" %s' % (kind, regex, spec))


def __lldb_init_module(debugger, internal_dict):
    mod = __name__ if __name__ != "__main__" else "dlang_formatters"
    debugger.HandleCommand("type category define dlang")
    slice_rx = r"^.*\[\]\)*$|^_Array_.*$"
    _add(debugger, "synthetic", slice_rx, "--python-class %s.DSliceSyntheticProvider" % mod)
    _add(debugger, "summary", slice_rx, "-e --python-function %s.d_slice_summary" % mod)
    str_rx = r"^((const|immutable|shared|inout)\()*(string|wstring|dstring)\)*$"
    _add(debugger, "synthetic", str_rx, "--python-class %s.DSliceSyntheticProvider" % mod)
    _add(debugger, "summary", str_rx, "-e --python-function %s.d_slice_summary" % mod)
    aa_rx = r"^.*\[[A-Za-z_(].*\]\)*$|^_AArray_.*$"
    _add(debugger, "synthetic", aa_rx, "--python-class %s.DAssocArraySyntheticProvider" % mod)
    _add(debugger, "summary", aa_rx, "-e --python-function %s.d_aa_summary" % mod)
    static_rx = r"^.*\[[0-9]+\]\)*$"
    _add(debugger, "synthetic", static_rx, "--python-class %s.DStaticArraySyntheticProvider" % mod)
    _add(debugger, "summary", static_rx, "-e --python-function %s.d_static_summary" % mod)
    _add(debugger, "summary", r"^.*delegate\(.*\)$", "-e --python-function %s.d_delegate_summary" % mod)
    for name in ("byte", "ubyte", "signed char", "unsigned char"):
        debugger.HandleCommand('type format add -w dlang -f decimal "%s"' % name)
        debugger.HandleCommand('type summary add -w dlang -e --python-function %s.d_int8_summary "%s"' % (mod, name))
    _add(debugger, "summary", r"^((const|immutable|shared|inout)\()*(byte|ubyte|signed char|unsigned char)\)*$", "-e --python-function %s.d_int8_summary" % mod)
    debugger.HandleCommand("type category enable dlang")
    debugger.HandleCommand("command script add -f %s.dlang_status dlang_status" % mod)
    print("dlang formatters loaded (category dlang)")
