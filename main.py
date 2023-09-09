import pygame
import sys

# Инициализация Pygame
pygame.init()

# Размеры окна
WIDTH, HEIGHT = 400, 500  # Увеличиваем высоту для интерфейса

# Создание окна
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Шашки")

# Цвета
BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
RED = (255, 0, 0)
ORANGE = (255, 165, 0)  # Оранжевый цвет для контуров

# Размеры клеток на доске
CELL_SIZE = WIDTH // 8

# Создание игровой доски
initial_board = [[0, 1, 0, 1, 0, 1, 0, 1],
                 [1, 0, 1, 0, 1, 0, 1, 0],
                 [0, 1, 0, 1, 0, 1, 0, 1],
                 [0, 0, 0, 0, 0, 0, 0, 0],
                 [0, 0, 0, 0, 0, 0, 0, 0],
                 [2, 0, 2, 0, 2, 0, 2, 0],
                 [0, 2, 0, 2, 0, 2, 0, 2],
                 [2, 0, 2, 0, 2, 0, 2, 0]]

# Создание списка для хранения координат каждой шашки
pieces = []

for row in range(8):
    for col in range(8):
        if initial_board[row][col] == 1:
            pieces.append({'type': 'white', 'row': row, 'col': col})
        elif initial_board[row][col] == 2:
            pieces.append({'type': 'black', 'row': row, 'col': col})

# Переменные для drag and drop
selected_piece = None
offset_x, offset_y = 0, 0
dragging = False

# Создание кнопки "Новая игра"
new_game_button = pygame.Rect(10, HEIGHT - 50, 100, 40)  # Располагаем внизу окна
button_color = ORANGE

# Функция для отрисовки шашек на доске
def draw_pieces():
    for piece in pieces:
        x = piece['col'] * CELL_SIZE + CELL_SIZE // 2
        y = piece['row'] * CELL_SIZE + CELL_SIZE // 2
        radius = CELL_SIZE // 2 - 5
        if piece['type'] == 'white':
            pygame.draw.circle(screen, WHITE, (x, y), radius)
        elif piece['type'] == 'black':
            pygame.draw.circle(screen, BLACK, (x, y), radius)

        # Рисуем оранжевый контур вокруг каждой шашки
        pygame.draw.circle(screen, ORANGE, (x, y), radius, 2)

# Функция для сброса доски к начальному состоянию
def reset_board():
    pieces.clear()
    for row in range(8):
        for col in range(8):
            if initial_board[row][col] == 1:
                pieces.append({'type': 'white', 'row': row, 'col': col})
            elif initial_board[row][col] == 2:
                pieces.append({'type': 'black', 'row': row, 'col': col})

# Главный цикл игры
running = True
while running:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

        if event.type == pygame.MOUSEBUTTONDOWN:
            if not dragging:
                for piece in pieces:
                    x = piece['col'] * CELL_SIZE + CELL_SIZE // 2
                    y = piece['row'] * CELL_SIZE + CELL_SIZE // 2
                    radius = CELL_SIZE // 2 - 5
                    if pygame.Rect(x - radius, y - radius, 2 * radius, 2 * radius).collidepoint(event.pos):
                        selected_piece = piece
                        offset_x = x - event.pos[0]
                        offset_y = y - event.pos[1]
                        dragging = True

            # Проверяем, была ли нажата кнопка "Новая игра"
            if new_game_button.collidepoint(event.pos):
                reset_board()

        if event.type == pygame.MOUSEBUTTONUP:
            if dragging:
                x = event.pos[0] + offset_x
                y = event.pos[1] + offset_y
                new_col = x // CELL_SIZE
                new_row = y // CELL_SIZE
                if 0 <= new_row < 8 and 0 <= new_col < 8:
                    selected_piece['row'] = new_row
                    selected_piece['col'] = new_col
                dragging = False

    # Очистка экрана
    screen.fill(BLACK)

    # Отрисовка игровой доски
    for row in range(8):
        for col in range(8):
            if (row + col) % 2 == 0:
                pygame.draw.rect(screen, WHITE, (col * CELL_SIZE, row * CELL_SIZE, CELL_SIZE, CELL_SIZE))
            else:
                pygame.draw.rect(screen, RED, (col * CELL_SIZE, row * CELL_SIZE, CELL_SIZE, CELL_SIZE))

    # Отрисовка кнопки "Новая игра"
    pygame.draw.rect(screen, button_color, new_game_button)
    font = pygame.font.Font(None, 36)
    text = font.render("Новая игра", True, BLACK)
    text_rect = text.get_rect(center=new_game_button.center)
    screen.blit(text, text_rect)

    # Отрисовка шашек
    draw_pieces()

    # Если выбрана шашка, отрисовываем её над другими шашками
    if selected_piece:
        x = pygame.mouse.get_pos()[0] + offset_x
        y = pygame.mouse.get_pos()[1] + offset_y
        radius = CELL_SIZE // 2 - 5
        if selected_piece['type'] == 'white':
            pygame.draw.circle(screen, WHITE, (x, y), radius)
        elif selected_piece['type'] == 'black':
            pygame.draw.circle(screen, BLACK, (x, y), radius)

    # Обновление экрана
    pygame.display.flip()

# Завершение игры
pygame.quit()
sys.exit()
