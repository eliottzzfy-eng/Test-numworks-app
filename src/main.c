#include <ion.h>
#include <kandinsky.h>
#include <string.h>
#include <stdio.h> // For snprintf

// --- Game Constants ---
#define BIRD_WIDTH 8
#define BIRD_HEIGHT 6
#define BIRD_START_X 20
#define BIRD_GRAVITY 0.35f
#define BIRD_FLAP_VELOCITY -5.0f // Negative for upwards movement

#define PIPE_WIDTH 12
#define PIPE_GAP_HEIGHT 45 // Gap between top and bottom pipe
#define PIPE_SPEED 2.0f
#define PIPE_SPACING 100 // Distance between pipe pairs

#define GROUND_HEIGHT 15 // Height of the ground from the bottom
#define SCORE_MAX_DIGITS 4 // Max digits for score display

// --- Game Colors ---
const KDColor COLOR_BACKGROUND = KDColorRGB(135, 206, 235); // Sky blue
const KDColor COLOR_BIRD = KDColorYellow;
const KDColor COLOR_PIPE = KDColorGreen;
const KDColor COLOR_GROUND = KDColorRGB(222, 184, 135); // BurlyWood
const KDColor COLOR_TEXT = KDColorBlack;
const KDColor COLOR_GAME_OVER_TEXT = KDColorRed;
const KDColor COLOR_SCORE_TEXT = KDColorWhite;

// --- Game State Variables ---
float birdY;
float birdVelocityY;
bool gameStarted;
bool gameOver;
int score;

// Pipe positions and heights
typedef struct {
    int x;
    int gapY; // Y coordinate of the top of the gap
    bool passed; // Has the bird passed this pipe for scoring?
} Pipe;

#define MAX_PIPES 3 // How many pipe pairs can be on screen/coming up
Pipe pipes[MAX_PIPES];

// --- Function Prototypes ---
void initGame();
void updateGame();
void drawGame();
void drawBird();
void drawPipes();
void drawGround();
void drawScore();
void drawGameOverScreen();
void flapBird();
void handleInput();

// --- Main application loop ---
void ion_app_main() {
    initGame();

    while (1) {
        // Handle input immediately for responsiveness
        handleInput();

        if (gameStarted && !gameOver) {
            updateGame();
        }

        // Always draw to update the screen
        drawGame();
        Ion_flush(); // Refresh the screen
    }
}

// --- Game Initialization ---
void initGame() {
    birdY = (float)(Kandinsky::k_height / 2);
    birdVelocityY = 0;
    gameStarted = false;
    gameOver = false;
    score = 0;

    // Initialize pipes
    for (int i = 0; i < MAX_PIPES; ++i) {
        pipes[i].x = Kandinsky::k_width + i * PIPE_SPACING; // Stagger initial pipe positions
        pipes[i].gapY = (Kandinsky::k_height / 3) + (Ion::random() % (Kandinsky::k_height / 3)); // Random gap height
        pipes[i].passed = false;
    }
}

// --- Game Update Logic ---
void updateGame() {
    // Update bird position
    birdVelocityY += BIRD_GRAVITY;
    birdY += birdVelocityY;

    // Clamp bird to top of screen (or let it go off a bit)
    if (birdY < 0) {
        birdY = 0;
        birdVelocityY = 0; // Stop upward momentum if hit ceiling
    }

    // Check for collision with ground
    if (birdY + BIRD_HEIGHT > Kandinsky::k_height - GROUND_HEIGHT) {
        birdY = Kandinsky::k_height - GROUND_HEIGHT - BIRD_HEIGHT;
        gameOver = true;
        birdVelocityY = 0; // Stop bird movement
        return; // Game over, no further updates
    }

    // Update pipes
    for (int i = 0; i < MAX_PIPES; ++i) {
        pipes[i].x -= PIPE_SPEED;

        // Reset pipe if it goes off screen
        if (pipes[i].x < -PIPE_WIDTH) {
            pipes[i].x = Kandinsky::k_width + (MAX_PIPES - 1) * PIPE_SPACING; // Place it after the last pipe
            pipes[i].gapY = (Kandinsky::k_height / 4) + (Ion::random() % (Kandinsky::k_height / 2)); // Random gap height
            pipes[i].passed = false;
        }

        // Check for collision with pipe
        // Bird's X range: BIRD_START_X to BIRD_START_X + BIRD_WIDTH
        // Pipe's X range: pipes[i].x to pipes[i].x + PIPE_WIDTH
        bool birdOverlapsX = (BIRD_START_X + BIRD_WIDTH > pipes[i].x) && (BIRD_START_X < pipes[i].x + PIPE_WIDTH);

        if (birdOverlapsX) {
            bool birdOverlapsTopPipe = (birdY < pipes[i].gapY);
            bool birdOverlapsBottomPipe = (birdY + BIRD_HEIGHT > pipes[i].gapY + PIPE_GAP_HEIGHT);

            if (birdOverlapsTopPipe || birdOverlapsBottomPipe) {
                gameOver = true;
                return;
            }

            // Check for score
            if (!pipes[i].passed && BIRD_START_X > pipes[i].x + PIPE_WIDTH) {
                score++;
                pipes[i].passed = true;
            }
        }
    }
}

// --- Drawing Functions ---
void drawGame() {
    Kandinsky::fill_rect(KDRect(0, 0, Kandinsky::k_width, Kandinsky::k_height), COLOR_BACKGROUND);

    drawPipes();
    drawGround();
    drawBird();
    drawScore();

    if (gameOver) {
        drawGameOverScreen();
    } else if (!gameStarted) {
        // Draw "Press OK to start"
        const char * start_msg = "Press OK to start!";
        KDRect textRect = KDRect(0, Kandinsky::k_height / 2 - 10, Kandinsky::k_width, 20);
        Kandinsky::draw_string(start_msg, textRect.origin(), KDFont::LargeFont, COLOR_TEXT, COLOR_BACKGROUND);
    }
}

void drawBird() {
    Kandinsky::fill_rect(KDRect(BIRD_START_X, (int)birdY, BIRD_WIDTH, BIRD_HEIGHT), COLOR_BIRD);
    // Draw a simple wing triangle
    KDPoint wingPoints[] = {
        KDPoint(BIRD_START_X + BIRD_WIDTH / 2, (int)birdY + BIRD_HEIGHT / 2),
        KDPoint(BIRD_START_X + BIRD_WIDTH, (int)birdY + BIRD_HEIGHT / 4),
        KDPoint(BIRD_START_X + BIRD_WIDTH, (int)birdY + 3 * BIRD_HEIGHT / 4)
    };
    Kandinsky::fill_rect_with_triangles(wingPoints, 1, COLOR_BACKGROUND); // Use background color to make it look like a cut-out wing
}

void drawPipes() {
    for (int i = 0; i < MAX_PIPES; ++i) {
        int pipeX = pipes[i].x;
        int pipeGapY = pipes[i].gapY;

        // Top pipe
        Kandinsky::fill_rect(KDRect(pipeX, 0, PIPE_WIDTH, pipeGapY), COLOR_PIPE);
        // Bottom pipe
        Kandinsky::fill_rect(KDRect(pipeX, pipeGapY + PIPE_GAP_HEIGHT, PIPE_WIDTH, Kandinsky::k_height - (pipeGapY + PIPE_GAP_HEIGHT) - GROUND_HEIGHT), COLOR_PIPE);
    }
}

void drawGround() {
    Kandinsky::fill_rect(KDRect(0, Kandinsky::k_height - GROUND_HEIGHT, Kandinsky::k_width, GROUND_HEIGHT), COLOR_GROUND);
}

void drawScore() {
    char scoreStr[SCORE_MAX_DIGITS + 1];
    snprintf(scoreStr, sizeof(scoreStr), "%d", score);
    Kandinsky::draw_string(scoreStr, KDPoint(Kandinsky::k_width - 10 - KDFont::LargeFont->stringWidth(scoreStr), 10), KDFont::LargeFont, COLOR_SCORE_TEXT, COLOR_BACKGROUND);
}

void drawGameOverScreen() {
    const char * go_msg = "GAME OVER!";
    const char * restart_msg = "Press OK to restart.";
    KDRect goRect = KDRect(0, Kandinsky::k_height / 2 - 20, Kandinsky::k_width, 20);
    KDRect restartRect = KDRect(0, Kandinsky::k_height / 2, Kandinsky::k_width, 20);

    Kandinsky::draw_string(go_msg, goRect.origin(), KDFont::LargeFont, COLOR_GAME_OVER_TEXT, COLOR_BACKGROUND);
    Kandinsky::draw_string(restart_msg, restartRect.origin(), KDFont::SmallFont, COLOR_TEXT, COLOR_BACKGROUND);
}

// --- Game Actions ---
void flapBird() {
    birdVelocityY = BIRD_FLAP_VELOCITY;
}

// --- Input Handling ---
void handleInput() {
    Ion::Keyboard::State keyboardState = Ion::Keyboard::scan();

    if (keyboardState.keyDown(Ion::Keyboard::Key::OK) || keyboardState.keyDown(Ion::Keyboard::Key::EXE)) {
        if (!gameStarted) {
            gameStarted = true;
            // First flap to start
            flapBird();
        } else if (gameOver) {
            initGame(); // Restart game
        } else {
            flapBird();
        }
    }
}
