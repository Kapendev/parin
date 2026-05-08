# NOTES

Work on microui's texture support. It's hard to use right and also WIP.

Microui's context being a global is maybe bad and should be changed...
A solution that keeps the global is to provide a module that is for debugging.
No idea, I also don't want to break code that depends on current microui being global.

Microui's could be cleaner for Parin (same types, less code, ...).
This can be fixed by including microui inside Joka.
The original repo could be just basic microui without the extras.
So, the original repo doesn't change anymore and the Joka version can go crazy with stuff.
