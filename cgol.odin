package cgol

import "base:runtime"
import "core:fmt"
import "core:math/rand"
import "core:strings"
import "core:time"

GRID_X :: 100
GRID_Y :: 25
GRID_SIZE :: GRID_Y * GRID_X
INITIAL_ALIVES :: 50 // Set 50% of the total to ALIVE
DELAY_MS :: 33 // 0.03333...
DEAD_CELL :: '.'
ALIVE_CELL :: '*'

Cell_State :: enum {
	Dead = 0,
	Alive,
}

App :: struct {
	temp_grid: [GRID_SIZE]Cell_State,
	main_grid: [GRID_SIZE]Cell_State,
}

init :: proc(app: ^App) {
	ALIVE_COUNT :: (GRID_SIZE * INITIAL_ALIVES) / 100

	for i in 0 ..< ALIVE_COUNT {
		app.main_grid[i] = Cell_State.Alive

	}
	rand.shuffle(app.main_grid[:])
}

draw :: proc(app: ^App) -> runtime.Allocator_Error {
	sb := strings.Builder{}
	strings.builder_init(&sb, GRID_SIZE + GRID_Y, context.temp_allocator) or_return
	defer free_all(context.temp_allocator)

	for y in 0 ..< GRID_Y {
		for x in 0 ..< GRID_X {
			index := y * GRID_X + x
			ch: u8
			if app.main_grid[index] == Cell_State.Alive {
				ch = ALIVE_CELL
			} else {
				ch = DEAD_CELL
			}
			strings.write_byte(&sb, ch) or_return
		}
		strings.write_byte(&sb, '\n') or_return
	}
	fmt.print(strings.to_string(sb))
	return .None
}

count_neighbors :: proc(main_grid: ^[GRID_SIZE]Cell_State, x: int, y: int) -> int {
	count := 0

	for dy := -1; dy <= 1; dy += 1 {
		for dx := -1; dx <= 1; dx += 1 {
			if dx == 0 && dy == 0 {
				continue
			}

			nx := x + dx
			ny := y + dy

			// Check if within grid bounds
			if nx >= 0 && nx < GRID_X && ny >= 0 && ny < GRID_Y {
				// Convert to 1D index and check state
				index := ny * GRID_X + nx
				if main_grid[index] == Cell_State.Alive {
					count += 1
				}
			}

		}
	}
	return count
}

update :: proc(app: ^App) {
	for y in 0 ..< GRID_Y {
		for x in 0 ..< GRID_X {
			neighbors := count_neighbors(&app.main_grid, x, y)
			index := y * GRID_X + x
			current_state := app.main_grid[index]

			if current_state == Cell_State.Alive {
				app.temp_grid[index] =
					neighbors <= 1 || neighbors >= 4 ? Cell_State.Dead : Cell_State.Alive
			} else {
				app.temp_grid[index] = neighbors == 3 ? Cell_State.Alive : Cell_State.Dead
			}
		}
	}
	app.main_grid = app.temp_grid
}

clear :: proc() {
	fmt.print("\x1b[H")
}

run :: proc(app: ^App) -> runtime.Allocator_Error {
	init(app)

	fmt.print("\x1b[2J")

	target_dt := time.Duration(DELAY_MS * time.Millisecond)

	for {
		start_time := time.now()

		clear()
		draw(app) or_return
		update(app)

		elapsed := time.since(start_time)
		if elapsed < target_dt {
			time.sleep(target_dt - elapsed)
		}
	}

	return .None
}

main :: proc() {

	app := App{}
	if run(&app) != .None {
		panic("failed to memory allocate")
	}
}
