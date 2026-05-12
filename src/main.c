/*
 * SDL3 Android Example
 * Author: H4bbit
 * Platform: Android / SDL3
 */
#define SDL_MAIN_USE_CALLBACKS
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <stdlib.h>
#include <time.h>

#define MAX_PARTICLES 500

typedef struct {
  float x, y;
  float vx, vy;
  SDL_Color color;
  float lifetime; // De 1.0 a 0.0
} Particle;

typedef struct {
  SDL_Window *window;
  SDL_Renderer *renderer;
  Particle particles[MAX_PARTICLES];
  int next_particle;
} AppState;

// Função auxiliar para criar uma partícula onde houve o toque
void EmitParticle(AppState *state, float x, float y) {
  Particle *p = &state->particles[state->next_particle];
  p->x = x;
  p->y = y;
  // Velocidade aleatória
  p->vx = ((float)(rand() % 100) - 50.0f) / 10.0f;
  p->vy = ((float)(rand() % 100) - 80.0f) / 10.0f;
  p->lifetime = 1.0f;
  p->color = (SDL_Color){rand() % 255, rand() % 255, rand() % 255, 255};

  state->next_particle = (state->next_particle + 1) % MAX_PARTICLES;
}

SDL_AppResult SDL_AppInit(void **appstate, int argc, char *argv[]) {
  SDL_Init(SDL_INIT_VIDEO);

  AppState *state = (AppState *)SDL_calloc(1, sizeof(AppState));
  *appstate = state;

  SDL_CreateWindowAndRenderer("Particulas SDL3", 0, 0, SDL_WINDOW_FULLSCREEN,
                              &state->window, &state->renderer);
  srand((unsigned int)time(NULL));

  return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppEvent(void *appstate, SDL_Event *event) {
  AppState *state = (AppState *)appstate;

  if (event->type == SDL_EVENT_QUIT) {
    return SDL_APP_SUCCESS;
  }

  // Suporte a multitoque e arrasto
  if (event->type == SDL_EVENT_FINGER_DOWN ||
      event->type == SDL_EVENT_FINGER_MOTION) {
    int w, h;
    SDL_GetWindowSize(state->window, &w, &h);
    float touchX = event->tfinger.x * w;
    float touchY = event->tfinger.y * h;

    // Emite algumas partículas por frame de movimento
    for (int i = 0; i < 5; i++) {
      EmitParticle(state, touchX, touchY);
    }
  }

  return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppIterate(void *appstate) {
  AppState *state = (AppState *)appstate;

  // Fundo escuro com leve rastro (alpha baixo no clear simula motion blur)
  SDL_SetRenderDrawColor(state->renderer, 10, 10, 15, 255);
  SDL_RenderClear(state->renderer);

  for (int i = 0; i < MAX_PARTICLES; i++) {
    Particle *p = &state->particles[i];
    if (p->lifetime > 0) {
      // Aplica gravidade e velocidade
      p->vy += 0.2f;
      p->x += p->vx;
      p->y += p->vy;
      p->lifetime -= 0.02f; // Partícula morre aos poucos

      // Desenha a partícula (quadrado pequeno)
      SDL_FRect rect = {p->x, p->y, 8.0f, 8.0f};
      SDL_SetRenderDrawColor(state->renderer, p->color.r, p->color.g,
                             p->color.b, (Uint8)(p->lifetime * 255));
      SDL_RenderFillRect(state->renderer, &rect);
    }
  }

  SDL_RenderPresent(state->renderer);
  return SDL_APP_CONTINUE;
}

void SDL_AppQuit(void *appstate, SDL_AppResult result) {
  AppState *state = (AppState *)appstate;
  if (state) {
    SDL_DestroyRenderer(state->renderer);
    SDL_DestroyWindow(state->window);
    SDL_free(state);
  }
  SDL_Quit();
}
