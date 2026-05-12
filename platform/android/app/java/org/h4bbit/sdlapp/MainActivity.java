package org.h4bbit.sdlapp;

import org.libsdl.app.SDLActivity;

public class MainActivity extends SDLActivity {

    @Override
    protected String[] getLibraries() {
        return new String[] {
            "sdl-android-app"
        };
    }
}
