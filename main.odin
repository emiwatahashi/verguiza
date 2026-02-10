package main

import k2 "karl2d"
import "core:math/rand"
import "core:math"
import "core:fmt"

Cardinal :: enum{
 South,
 North,
 East,
 West,
 South_West,
 South_East,
 North_West,
 North_East,
}

Entity :: struct {
 texture : k2.Texture,
 position : k2.Vec2,
 direction : k2.Vec2,
 rotation : f32,
 cardinal : Cardinal,
 health : int,
 shooting_time: f32,
}

camera : k2.Camera
tank : Entity
shots : [dynamic]Entity
enemy_texture : k2.Texture 
enemys : [dynamic]Entity
timer : f32
score : int
enemy_shots : [dynamic]Entity
lost : bool
lost_timer : f32
shot_sound : k2.Sound
enemy_destroyed_sound : k2.Sound
lost_sound : k2.Sound
marlboro_song : k2.Sound
play_song : bool
timer_song : f32 
game_speed : f32


init :: proc(){
 k2.init(1280, 720, "emi");
 camera.zoom = f32(k2.get_screen_width())/1920.0
 tank.texture = k2.load_texture_from_bytes(#load("textures/tankA.png"))
 tank.position = {960, 640}
 tank.health = 1
 enemy_texture = k2.load_texture_from_bytes(#load("textures/enemyA.png"))
 lost_timer = 2
 shot_sound = k2.load_sound_from_bytes(#load("sounds/shot.wav"))
 enemy_destroyed_sound = k2.load_sound_from_bytes(#load("sounds/enemy_destroyed.wav"))
 lost_sound = k2.load_sound_from_bytes(#load("sounds/lost.wav"))
 marlboro_song = k2.load_sound_from_bytes(#load("sounds/el_hijo_mayor.wav"))
 play_song = true
 game_speed = 1.0
}

step :: proc() -> bool {
  if !k2.update() do return false
  if timer_song >= 189{ 
   play_song = true
   timer_song = 0
  }
  if play_song {
   k2.play_sound(marlboro_song)
   play_song = false
  }
  if !play_song do timer_song += k2.get_frame_time()

  if lost && lost_timer > 0 do lost_timer -= k2.get_frame_time()
  if lost && k2.key_went_down(.Z) && lost_timer <= 0{
   tank.health = 1
   score = 0
   game_speed = 1.0
   clear(&shots)
   clear(&enemys)
   clear(&enemy_shots)
   lost = false
   lost_timer = 2
  }
  tank_speed : f32 = 150 * game_speed
  if k2.key_is_held(.X) do tank_speed *= 2
  if k2.key_is_held(.Up){
   tank.position.y -= tank_speed * k2.get_frame_time()
  }
  if k2.key_is_held(.Down){ 
   tank.position.y += tank_speed * k2.get_frame_time()
  }
  if k2.key_is_held(.Right){
   tank.position.x += tank_speed * k2.get_frame_time()
  }
  if k2.key_is_held(.Left){
   tank.position.x -= tank_speed * k2.get_frame_time()
  }
  if k2.key_is_held(.Up) do tank.cardinal = .North
  if k2.key_is_held(.Down) do tank.cardinal = .South
  if k2.key_is_held(.Right) do tank.cardinal = .East
  if k2.key_is_held(.Left) do tank.cardinal = .West
  if k2.key_is_held(.Left) && k2.key_is_held(.Down) do tank.cardinal = .South_West
  if k2.key_is_held(.Left) && k2.key_is_held(.Up)   do tank.cardinal = .North_West
  if k2.key_is_held(.Right) && k2.key_is_held(.Up)    do tank.cardinal = .North_East
  if k2.key_is_held(.Right) && k2.key_is_held(.Down)  do tank.cardinal = .South_East
  if k2.key_went_down(.Z) && !lost {
   k2.play_sound(shot_sound)
   shot : Entity = {position = {tank.position.x, tank.position.y},
   cardinal = tank.cardinal}
   append(&shots, shot)
  }

  timer += k2.get_frame_time()
  if timer >= 1.0 && !lost {
   timer = 0
   enemy : Entity
   enemy.texture = enemy_texture
   enemy.position = {rand.float32_range(0, 1920), rand.float32_range(0, 1080)}
   padd : f32 = 200.0
   for (enemy.position.x < tank.position.x + padd && enemy.position.x > tank.position.x - padd &&
    enemy.position.y < tank.position.y + padd && enemy.position.y > tank.position.y - padd)
   {
    enemy.position = {rand.float32_range(0, 1920), rand.float32_range(0, 1080)}
   }
   enemy.health = 3
   radians : f32 = rand.float32_range(0, 3.141592*2)
   enemy.rotation = radians
   enemy.direction = {-math.sin(enemy.rotation+1/2*math.PI),math.cos(enemy.rotation+1/2*math.PI)}
   enemy.shooting_time = rand.float32_range(0.5, 1.5)

   append(&enemys, enemy)
  }
  if tank.cardinal == .North do tank.rotation = 3.141592*1
  if tank.cardinal == .South do tank.rotation = 0.0
  if tank.cardinal == .East do tank.rotation = 3.141592*3/2
  if tank.cardinal == .West do tank.rotation = 3.141592*1/2
  if tank.cardinal == .South_West do tank.rotation = 3.141592*1/4
  if tank.cardinal == .North_West do tank.rotation = 3.141592*3/4
  if tank.cardinal == .North_East do tank.rotation = 3.141592*5/4
  if tank.cardinal == .South_East do tank.rotation = 3.141592*7/4
  if tank.position.y >= 1080 do tank.position.y = 0
  if tank.position.x >= 1920 do tank.position.x = 0
  if tank.position.y < 0 do tank.position.y = 1080
  if tank.position.x < 0 do tank.position.x = 1920
  for &shot, i in shots
  {
   speed : f32 = 800 * game_speed
   switch shot.cardinal{
    case .North: shot.position += {0, -speed * k2.get_frame_time()}
    case .South: shot.position += {0, +speed * k2.get_frame_time()}
    case .East: shot.position += {speed * k2.get_frame_time(), 0}
    case .West: shot.position += {-speed * k2.get_frame_time(), 0}
    case .South_West: shot.position += {-speed * k2.get_frame_time(),  speed * k2.get_frame_time()}
    case .North_West: shot.position += {-speed * k2.get_frame_time(), -speed * k2.get_frame_time()}
    case .North_East: shot.position += { speed * k2.get_frame_time(), -speed * k2.get_frame_time()}
    case .South_East: shot.position += { speed * k2.get_frame_time(),  speed * k2.get_frame_time()}
   }
   for &enemy, j in enemys{
    padd : f32 = 45.0
    if (shot.position.x < enemy.position.x + padd && shot.position.x > enemy.position.x - padd) &&
     (shot.position.y < enemy.position.y + padd && shot.position.y > enemy.position.y - padd)
    {
     enemy.health -= 1
     if enemy.health == 0 { 
      k2.play_sound(enemy_destroyed_sound)
      unordered_remove(&enemys, j)
      score += 1
      game_speed += 0.01
     }
     unordered_remove(&shots, i)
    }
   }
   if shot.position.x < 0 || shot.position.y < 0 || shot.position.x >= 1920 || shot.position.y >= 1080 {
    unordered_remove(&shots, i)
   }
  }
  
  for &enemy in enemys{
   speed : f32 = 100 * game_speed
   enemy.position += enemy.direction * speed * k2.get_frame_time()
   if enemy.position.y >= 1080 do enemy.position.y = 0
   if enemy.position.x >= 1920 do enemy.position.x = 0
   if enemy.position.y < 0 do enemy.position.y = 1080
   if enemy.position.x < 0 do enemy.position.x = 1920
  }

  for &enemy in enemys{
   enemy.shooting_time -= k2.get_frame_time()
   if enemy.shooting_time < 0{
    enemy.shooting_time = rand.float32_range(1.5, 2.5)
    shot : Entity = {position = enemy.position, direction = enemy.direction}
    append(&enemy_shots, shot)
   }
  }
  for &enemy, i in enemys{
   padd : f32 = 80
   if (enemy.position.x < tank.position.x + padd && enemy.position.x > tank.position.x - padd) &&
    (enemy.position.y < tank.position.y + padd && enemy.position.y > tank.position.y - padd)
   {
    tank.health -= 1
    unordered_remove(&enemys, i)
   }
  }

  for &shot, i in enemy_shots{
   speed : f32 = 120 * game_speed
   shot.position += shot.direction * speed * k2.get_frame_time()
   padd : f32 = 45
   if (shot.position.x < tank.position.x + padd && shot.position.x > tank.position.x - padd) &&
    (shot.position.y < tank.position.y + padd && shot.position.y > tank.position.y - padd)
   {
    tank.health -= 1
    unordered_remove(&enemy_shots, i)
   }
   if shot.position.x < 0 || shot.position.y < 0 || shot.position.x >= 1920 || shot.position.y >= 1080 {
    unordered_remove(&enemy_shots, i)
   }
  }
  if tank.health <= 0 && lost == false{
   lost = true
   k2.play_sound(lost_sound)
  }

  
  
  k2.set_camera(camera)
  k2.clear(k2.BLACK)
  k2.draw_text(fmt.tprintf("%v", score), {1920/2, 1080/6}, 160, k2.WHITE)
  if lost do k2.draw_text("YOU LOSE", {1920/3, 1080/3}, 200, k2.WHITE)
  if lost do k2.draw_text("continue?", {1920/2, 1080/2}, 60, k2.WHITE)
  for shot in shots do k2.draw_circle(shot.position, 10, k2.WHITE)
  for shot in enemy_shots do k2.draw_circle(shot.position, 10, k2.RED)
  if !lost do k2.draw_texture_ex(tank.texture, k2.get_texture_rect(tank.texture),
   {tank.position.x, tank.position.y, f32(tank.texture.width), f32(tank.texture.height)}, 
   {f32(tank.texture.width)/2, f32(tank.texture.height)/2}, tank.rotation)
  for enemy in enemys{
   k2.draw_texture_ex(enemy.texture, k2.get_texture_rect(enemy.texture),
    {enemy.position.x, enemy.position.y, f32(enemy.texture.width), f32(enemy.texture.height)}, 
   {f32(enemy.texture.width)/2, f32(enemy.texture.height)/2}, enemy.rotation)
  }
  k2.present()
  free_all(context.temp_allocator)
  return true
}

shutdown :: proc()
{
 k2.shutdown()
}

main :: proc()
{
 init()
 for step() {}
 shutdown()
}
