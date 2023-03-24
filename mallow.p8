pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--mellow
--by luca harris

darker={
 [0]=0,0,1,1,
 2,1,13,6,
 2,8,4,3,
 1,1,2,5
}

function next_darker(d)
 local t={}
 for i=0,15 do
  t[i]=darker[d[i]]
 end
 return t
end

darker2=next_darker(darker)
darker3=next_darker(darker2)
darker4=next_darker(darker3)

darkers={
 darker,
 darker2,
 darker3,
 darker4,
}

function smoothstep(x)
 return x*x*(3-2*x)
end

function get_tile(gx,gy)
 return mget(gx/8,gy/8)
end

levels_cleared=0

transition={
 active=false,
}

intro={
 fade=true,
 fadet=0,
 active=true,
 done=false,
 t=0,
 k=1,
}
function intro.update()
 if intro.fade then
  --fade in
  local len=40
  if intro.fadet>len then
   --fade done
   intro.fade=false
   pal()
  else
   --fade active
   local k=intro.fadet/len
   
   --colours
   local d=darkers[1+flr((#darkers-1)*(1-k))]
   for i=0,15 do
    pal(i,d[i],1)
   end
   
   intro.fadet+=1
  end
 elseif not intro.active then
  --end of intro
  --fade hud in
  if intro.t<60 then
   local len=40
   intro.k=1-smoothstep(min(1,intro.t/len))
   intro.t+=1
  else
   intro.done=true
  end
 end
end

function gen_level()
 cls()
 for i=1,15 do
  pal(i,0,1)
 end
 
 --gen a bunch of circles
 local cs={}
 --iterate radii
 for i=1,8 do
  local r=10-i
  
  --number of circles to try
  --to generate
  local n=({
   1,1,2,3,3,50,100,500
  })[i]
  
	 for j=0,n do
	  --make sure circle isnt
	  --clipped by edge of map.
	  local x=flr(rnd2(r,128-r))
	  local y=flr(rnd2(r,64-r))
	  
	  --check circle is far enough
	  --from rest of circles
	  local okay=true
	  for c in all(cs) do
	   local dx=x-c.x
	   local dy=y-c.y
	   local minr=r+c.r
	   
	   --first two checks are
	   --for performance
	   if abs(dx)<minr and abs(dy)<minr and sqrt(dx*dx+dy*dy)<minr then
	    okay=false
	    break
	   end
	  end
	  
	  if okay then
	   add(cs,{
	    x=x,
	    y=y,
	    r=r,
	   })
	   
	   circfill(x,y,r,1)
	   
	   --add flowers
	   if rnd()<0.35+r/9 then
			  local t=rnd2(2,4)
			  local r2=max(r/2,r-3)
			  for i=1,rnd2(r/2,r*3) do
			   local x2=x+rnd3(r2)
			   local y2=y+rnd3(r2)
				  if pget(x2,y2)==1 then
				   pset(x2,y2,t)
				  end
			  end
	   end
	  end
	 end
 end
 
 --small lilypads
 --need 3x3 water area
 for n=0,90 do
  local x=rnd(128)
  local y=rnd(64)
  for i=-1,1 do 
   for j=-1,1 do
    if pget(x+i,y+j)!=0 then
     goto nxt
    end
   end
  end
  pset(x,y,4)
  ::nxt::
 end
 
 --large liliypad
 --need 4x4 water area
 for n=0,250 do
  local x=rnd(126)
  local y=rnd(62)
  for i=0,3 do 
   for j=0,3 do
    if pget(x+i,y+j)!=0 then
     goto nxt
    end
   end
  end
  pset(x+1,y+1,5)
  pset(x+2,y+1,6)
  pset(x+1,y+2,7)
  pset(x+2,y+2,8)
  ::nxt::
 end
	   
 --init pickups
 pickups={}
 pickup_count=0
 local np=4+levels_cleared*2.5
 for i=1,rnd2(np,np*1.5) do
  local c=cs[1+flr(rnd(#cs))]
  if not c.picked then
   c.picked=true
	  add(pickups,{
	   active=true,
	   x=flr(c.x*8),
	   y=flr(c.y*8),
	  })
	 end
 end
 
 --copy to map
 for x=0,127 do
  for y=0,63 do
   mset(x,y,pget(x,y))
  end
 end
 
 --init player
	p={
	 vx=0,
	 vy=0,
	 z=0,
	 d=0,
	 j=false,
	 f=3,
	 cr=false,
	 crt=0,
	}
	
	if levels_cleared==0 then
	 --spawn set amount above
	 --highest island
	 local miny=64
	 local minx=0
	 for c in all(cs) do
	  local top=c.y-c.r
	  if top<miny then
	   miny=top
	   minx=c.x
	  end
	 end
	 p.x=minx*8+4
	 p.y=miny*8-52
	else
	 --spawn somewhere on land
	 while true do
	  local mx=rnd(128)
	  local my=rnd(64)
	  if mget(mx,my)!=0 then
	   p.x=flr(mx)*8+4
	   p.y=flr(my)*8+4
	   break
	  end
	 end
	end
 
 --init camera
 cam={
	 x=p.x,
	 y=p.x,
	 vx=0,
	 vy=0,
	 dx=0,
	 dy=0,
	}
	
	--:)
	pal()
end

function play_music(first)
 music(3,first and 0 or 3500,7)
 menuitem(1,"stop music",stop_music)
end

function stop_music()
 music(-1,1000)
 menuitem(1,"play music",play_music)
end

hud_is_shown=false
function show_hud()
 hud_is_shown=true
 menuitem(2,"hide hud",hide_hud)
end
function hide_hud()
 hud_is_shown=false
 menuitem(2,"show hud",show_hud)
end

function _init()
 cls()
 flip()

 gen_level()
 
 --intro ambience
 music(0,500)
end

lix=0
liy=0
function _update60()
 --directional input
 local ix,iy=0,0
 if(btn(0))ix-=1
 if(btn(1))ix+=1
 if(btn(2))iy-=1
 if(btn(3))iy+=1
 
 --intro stuff
 if not intro.done then
  intro.update()
 end
 
 --busy transitioning
 if transition.active then
  if transition.phase==0 then
   --blur in
   --set width of "pixel"
   --should be a power of 2
   transition.w=2^flr(2+transition.t/2)
	  
	  if transition.w>=64 then
	   --move to phase two
    levels_cleared+=1
	   gen_level()
	   transition.phase=1
	   transition.t=0
	  else
    transition.t+=1
	   return
	  end
	 else
	  --blur out
	  --reverse of before
	  transition.w=2^flr(5-transition.t/2)
	  
	  if transition.w<=1 then
	   --transition complete
	   transition.active=false
	  else
    transition.t+=1
	   return
	  end
  end
 end
 
 --completed level?
 if pickup_count==#pickups then
  --begin level transition
  transition.active=true
  transition.t=0
  transition.w=2
  transition.phase=0
  return
 end
 
 --get tile player is on
 local tile=get_tile(p.x,p.y)
 local above_water=tile==0
 local is_water=above_water and not p.j
 
 if p.cr then
  --charging roll
  if not btn(5) then
   --start roll!
   p.cr=false
   local v=min(p.crt/8,3)
   local a=p.f/4
   p.vx=cos(a)*v
   p.vy=sin(a)*v
  else
   --charge more
   
   --spawn particles
   local a=p.f/4+.5+rnd3(0.07)
   local v=min(0.4+p.crt*.05,1)
   local r=3
   v=rnd2(v,v*1.4)
   smoke(
    p.x+cos(a)*r,p.y-2+sin(a),
    cos(a)*v,sin(a)*v,
    1
   )
   p.crt+=1
  end
 else
  --normal movement
  
  --change in directional input
  local cx=lix!=ix
  local cy=liy!=iy
  
  --which way are we facing?
  if cx or cy then
   if ix!=0 and iy!=0 then
    --if diagonal, use most
    --recent change
    if cx then
     p.f=ix>0 and 0 or 2
    else
     p.f=iy>0 and 3 or 1
    end
   elseif ix!=0 then
    --horizontal
    p.f=ix>0 and 0 or 2
   elseif iy!=0 then
    --vertical
    p.f=iy>0 and 3 or 1
   end
  end
	 
	 if btn(5) and not p.j then
	  --init charge roll
	  p.cr=true
	  p.crt=0
	  p.vx=0
	  p.vy=0
	 else
		 --movement
		 local a=is_water and 0.1 or 0.15
		 local da=p.j and 0 or (is_water and 0.5 or a)
		 local mv=p.j and (p.jw and 1 or 2) or (is_water and 1 or 2)
		 local v=sqrt(p.vx^2+p.vy^2)
		 
		 --deaccleration
		 if ix==0 then
		  p.vx=shrink(p.vx,da)
		 end
		 if iy==0 then
		  p.vy=shrink(p.vy,da)
		 end
		 
		 --limit velocity in water
		 if is_water then
    if v>mv then
     local k=mv/v
     p.vx*=k
     p.vy*=k
    end
		 end
		 
		 local v2=p.vx^2+p.vy^2
		 local v=sqrt(v2)
		 
		 --base acceleration
		 local ax=ix*a
		 local ay=iy*a
		 
		 if v<0.1 then
		  --when slow we can
		  --accelerate in
		  --any direction
		  p.vx+=ax
		  p.vy+=ay
		 else
		  --prevent player from going
		  --too fast. we'll use the
		  --quake method:
		  
		  --project acc. vector onto
		  --vel. vector (get the acc.
		  --component parallel to
		  --velo.)
			 local dot=ax*p.vx+ay*p.vy
			 local pak=dot/v2
			 local pax=p.vx*pak
			 local pay=p.vy*pak
			 
			 --get the vector rejection
			 --(the acc. component
			 --perpendicular to velo.)
			 local rax=ax-pax
			 local ray=ay-pay
			 
			 --clamp projection when
			 --accelerating (dot>0)
			 if dot>0 then
			  local rav=sqrt(pax^2+pay^2)
			  if v>=mv then
			   --cant accelerate higher
			   pax=0
			   pay=0
			  elseif rav+v>mv then
			   --accelerate up to max
			   local k=(mv-v)/rav
			   pax*=k
			   pay*=k
			  end
			 end
			 
			 --:)
			 p.vx+=pax+rax
			 p.vy+=pay+ray
			end
			
			--movement particles
			local v=sqrt(p.vx^2+p.vy^2)
			if not p.j then
			 if is_water then
			  --v shaped ripple
			  if v>=0.5 then
			   local k=0.3/v
			   local d=1.5/v
					 droplet(
		     p.x-p.vy*d,
		     p.y+p.vx*d,
		     -p.vy*k,
		     p.vx*k
		    )
		    droplet(
		     p.x+p.vy*d,
		     p.y-p.vx*d,
		     p.vy*k,
		     -p.vx*k
		    )
		   end
			 else
			  --dust trail
			  if v>=1.8 and p.d%2<1 then
					 local k=0.5/v
					 smoke(
		     p.x,
		     p.y-1,
		     -p.vx*k+rnd3(.3),
		     -p.vy*k+rnd3(.3),
		     1.3
		    )
		   end
		  end
			end
		 
		 if p.j then
		  --currently jumping
		  --gravity
		  p.vz-=0.1
		  
		  p.z+=p.vz
		  
		  if p.z<=0 then
		   --landed from jump
		   p.z=0
		   p.j=false
		   
		   --landing fx
		   if above_water then
		    --sploosh
		    sfx(62)
		    
		    --circular water splash
		    local n=99
			   for i=1,n do
			    local a=i/n
			    local v=p.jw and 0.4 or 0.8
			    local r=1.5
			    droplet(
			     p.x+cos(a)*r,
			     p.y+sin(a)*r,
			     cos(a)*v,
			     sin(a)*v
			    )
			   end
		   else
		    --doof
		    sfx(61)
		    
		    --impact dust
		    local n=12
			   for i=1,n do
			    local a=i/n+rnd3(1/n/2)
			    local kx=0.8
			    local ky=0.7
			    local r=2
			    smoke(
			     p.x+cos(a)*r*kx,
			     p.y-1+sin(a)*r*ky,
			     cos(a)*kx,
			     sin(a)*ky,
			     1
			    )
			   end
		   end
		  end
		 else
		  --on the ground.
		  if btn(4) then
		   --start jump
		   
		   --jump is slower in water:
		   --1 save if we jumped from
		   --  water so we can limit
		   --  air velocity
		   --2 jump is shorter
		   p.j=true
		   p.jw=is_water
					p.vz=is_water and 0.65 or 1.25
					
					--boing!
					sfx(is_water and 58 or 60)
					
					--poof particles
					for i=1,4 do
					 smoke(p.x+rnd3(3),p.y+rnd3(3),0,0,1)
					end
		  end
		 end
		 
		 --distance walked.
		 --we reset the distance
		 --when not moving
		 if ix!=0 or iy!=0 then
		  p.d+=abs(v)/6
		 else
		  p.d=0
		 end
	 end
 end
 
 --add velocity
 local v=sqrt(p.vx^2+p.vy^2)
 p.x+=p.vx
 p.y+=p.vy
 
 --handle intro end
 if intro.active then
  if not above_water then
   intro.active=false
   play_music(true)
   show_hud()
  end
 end
 
 --check pickup collisions
 if p.z<3 then
	 for pick in all(pickups) do
	  if pick.active then
	   if abs(p.x-pick.x)<=8 and abs(p.y-pick.y)<=8 then
		   --mark collected
		   pick.active=false
		   pickup_count+=1
		   
		   --boop
		   sfx(pickup_count>=#pickups and 59 or 63)
		   
		   --poof
		   for i=1,rnd2(7,10) do
		    pollen(pick.x,pick.y)
		   end
		  end
	  end
	 end
	end
 
 --save current input
 if not p.cr then
  lix=ix
  liy=iy
 end
 
 local cama=0.036
 local camd=32
 local tdx=v==0 and 0 or (p.vx/v)*camd
 local tdy=v==0 and 0 or (p.vy/v)*camd
 cam.dx+=(tdx-cam.dx)*cama
 cam.dy+=(tdy-cam.dy)*cama
 
 cam.x=p.x+cam.dx
 cam.y=p.y+cam.dy
 
 update_particles()
end

function sign(x)
 return x==0 and 0 or sgn(x)
end

function shrink(x,d)
 if abs(x)<=d then
  return 0
 else
  return x-sgn(x)*d
 end
end

function rnd2(a,b)
 return a+rnd(b-a)
end

function rnd3(x)
 return rnd(x*2)-x
end

function rnd4(a,b)
 return (a+rnd(b-a))*sgn(rnd(2)-1)
end

ps={}
function particle(p)
 p.t=0
 add(ps,p)
end
function update_particles()
 for p in all(ps) do
  p.update(p)
  p.t+=1
  if p.kill then
   del(ps,p)
  end
 end
end
function draw_particles()
 for p in all(ps) do
  p.draw(p)
 end
end
function smoke(x,y,vx,vy,w)
 particle({
  x=x,
  y=y,
  vx=vx,
  vy=vy,
  w=rnd2(w,w*1.5),
  update=update_smoke,
  draw=draw_smoke,
 })
end
function update_smoke(p)
 p.x+=p.vx
 p.y+=p.vy
 p.w-=0.1
 p.vx*=0.95
 p.vy*=0.95
 p.kill=p.w<=0
end
function draw_smoke(p)
 --fillp(0x5a5a+0b.1)
 rectfill(
  p.x-p.w,p.y-p.w,
  p.x+p.w,p.y+p.w,
  7
 )
 --fillp()
end

function droplet(x,y,vx,vy)
 particle({
  x=x,
  y=y,
  vx=vx,
  vy=vy,
  age=rnd2(7,35),
  update=update_droplet,
  draw=draw_droplet,
 })
end
function update_droplet(p)
 local x2=p.x+p.vx
 local y2=p.y+p.vy
 if get_tile(x2,p.y)!=0 then
  p.vx=-p.vx
 else
  p.x=x2
 end
 if get_tile(p.x,y2)!=0 then
  p.vy=-p.vy
 else
  p.y=y2
 end
 --p.vx*=0.95
 --p.vy*=0.95
 p.kill=p.t>=p.age
end
function draw_droplet(p)
 pset(p.x,p.y,7)
end

function pollen(x,y)
 particle({
  x=x,
  y=y,
  vx=rnd4(0.1,0.27),
  vy=-rnd2(0.15,0.3),
  a=rnd(),
  r=rnd2(4,7),
  va=rnd4(0.01,0.02),
  age=rnd2(20,70),
  c=rnd()<.8 and 10 or 9,
  update=update_pollen,
  draw=draw_pollen,
 })
end
function draw_pollen(p)
 local t=p.t/p.age
 local da=0.1*(1-t)
 local x1=p.x+cos(p.a)*p.r
 local y1=p.y+sin(p.a)*p.r
 local x2=p.x+cos(p.a+da)*p.r
 local y2=p.y+sin(p.a+da)*p.r
 line(x1,y1,x2,y2,p.c)
end
function update_pollen(p)
 p.a+=p.va
 p.x+=p.vx
 p.y+=p.vy
 p.kill=p.t>=p.age
end

--function btext(s,x,y,fg,bg)
-- ?s,x,y+1,bg
-- ?s,x,y,fg
--end

tile_colors={
 [0]=12,11,11
}

function _draw()
 cls(12)
 
 camera(cam.x-64,cam.y-64)
 
 --tiles
 
 --top left tile
 local bgx0=flr((cam.x-64)/16)*16
 local bgy0=flr((cam.y-64)/16)*16
 
 for i=0,17 do
	 for j=0,17 do
	  --pixel pos
	  local x=bgx0+i*8
	  local y=bgy0+j*8
	  
	  --map pos
	  local mx=flr(x/8)
	  local my=flr(y/8)
	  
	  --tile index and type
	  local tilet=mget(mx,my)
	  local tile=min(tilet,1)
	  
	  --top or bottom edge?
	  local et=tile==0 and mget(mx,my-1)!=0
	  local eb=tile!=0 and mget(mx,my+1)==0
	  
	  if tile!=0 then
	   --if not water, draw!
	   rectfill(x,y,x+7,y+7,tile_colors[tile])
	   
	   --extra style
	   if tilet>=2 then
	    spr(tilet,x,y)
	   end
	  else
	   --dark edge in water
		  if et then
		   rectfill(x+1,y,x+6,y+1,3)
		  end
	  end
	  
	  --soft tile corners
	  
	  --get tiles around this one
	  local tt=min(1,mget(mx,my-1))
	  local tb=min(1,mget(mx,my+1))
	  local tl=min(1,mget(mx-1,my))
	  local tr=min(1,mget(mx+1,my))
	  local ttl=min(1,mget(mx-1,my-1))
	  local ttr=min(1,mget(mx+1,my-1))
	  local tbl=min(1,mget(mx-1,my+1))
	  local tbr=min(1,mget(mx+1,my+1))
	  
	  --top corners
	  if tt!=tile then
	   --top left
	   if tl!=tile and ttl!=tile then
	    pset(x,y,tile_colors[tl])
	    
	    if et then
	     rectfill(x,y+1,x,y+2,3)
	    end
	   end
	   
	   --top right
	   if tr!=tile and ttr!=tile then
	    pset(x+7,y,tile_colors[tr])
	    
	    if et then
	     rectfill(x+7,y+1,x+7,y+2,3)
	    end
	   end
	  end
	  
	  --bottom corners
	  if tb!=tile then
	   --bottom left
	   if tl!=tile and tbl!=tile then
	    pset(x,y+7,tile_colors[tl])
	    
	    if eb then
	     rectfill(x,y+7,x,y+8,3)
	    end
	   else
	    if eb then
	     rectfill(x,y+8,x,y+9,3)
	    end
	   end
	   
	   --bottom right
	   if tr!=tile and tbr!=tile then
	    pset(x+7,y+7,tile_colors[tr])
	    
	    if eb then
	     rectfill(x+7,y+7,x+7,y+8,3)
	    end
	   else
	    if eb then
	     rectfill(x+7,y+8,x+7,y+9,3)
	    end
	   end
	  end
	 end
 end
 
 --particles 
 draw_particles()
 
 --should hud be drawn
 local draw_hud=hud_is_shown and not intro.active
 
 --pickups
 local pick_icon_offset=62+intro.k*8
 
 for pick in all(pickups) do
  palt(0,false)
  palt(12,true)
  
  if pick.active then
   --distance from center
   --of screen
	  local dx=pick.x-cam.x
	  local dy=pick.y-cam.y
	  
	  if abs(dx)<68 and abs(dy)<68 then
	   --pickup onscreen
	   spr(16,pick.x-3,pick.y-3)
	  elseif draw_hud then
	   --pickup is offscreen.
	   --draw indicator at edge
	   
	   --gradient of line from
	   --screen center to pickup.
	   local m=dy/dx
	   local x,y
	   
	   if abs(m)<=1 then
	    --left/right
	    x=sgn(dx)*pick_icon_offset
	    y=sgn(dx)*62*m
	   else
	    --top/bot
	    x=sgn(dy)*62/m
	    y=sgn(dy)*pick_icon_offset
	   end
	   
	   --:)
	   spr(17,cam.x+x-3,cam.y+y-3)
	  end
	 end
	 
	 palt()
 end
 
 --player
 local pn --sprite index
 local pfh=false --flip horz.
 local pup=true --facing up
 local pdy=0 --delta y
 
 if p.cr then
  --charging roll
  if p.f%2==0 then
   pn=15
   pup=false
  else
   pn=14
  end
  
  --vibrate when high charge
  if p.crt>=16 then
   pdy=p.crt%2
  end
 else
  --normal movement
	 if p.f==0 then
	  pn=12
	  pup=false
	 elseif p.f==1 then
	  pn=13
	 elseif p.f==2 then
	  pn=12
	  pfh=true
	  pup=false
	 else
	  pn=11
	 end
 end
 
 --shadow while jumping
 if p.j then
  --get shadow rect bounds
  local x,y,w,h
  if pup then
   x=p.x-2
   y=p.y-2
   w=4
   h=2
  else
   x=p.x-1
   y=p.y-4
   w=2
   h=4
  end
  
  --per pixel darkening
  for sy=y,y+h do
	  for sx=x,x+w do
	   pset(sx,sy,darker[pget(sx,sy)])
	  end
  end
 end
 
 --walk animation
 if p.cr then
  --oof
 elseif not p.j and p.d>0 then
  if (p.d+0.2)*0.85%2>1 then
   --next row down
   pn+=16
  end
 end
 
 --draw player sprite
 local sx=p.x-3
 if not pfh then
  sx-=1
 end
 spr(pn,sx,p.y-p.z-7+pdy,1,1,pfh)
 
 --hud
 camera()
 
 --transition blur
 if transition.active then
  local w=transition.w
  local wm1=w-1
  for y=0,128-w,w do
   for x=0,128-w,w do
    rectfill(x,y,x+w-1,y+w-1,pget(x+w/2,y+w/2))
   end
  end
 end
 
 --hud text
 --if draw_hud then
 -- local s=pickup_count .. "/" .. #pickups
 -- btext(s,127-#s*4,1-intro.k*6,7,5)
 --end
 
 --debug
 --?stat(1),1,1,0
 --for i=1,4 do flip() end
end
__gfx__
00000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333300000000000000000011011000011100001101100000000000000000
000000000000000000000a0000700000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccc00000000000000000177177100177710017717710000000000000000
0070070000000000000000a007a70000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000177177100177710017717710011111000011100
00077000000000000000000000700000bbbb3333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000177777100177710017777710177777100177710
00077000000000000000000000000700bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000001717171e0177110017e77710177777100177710
00700700000000000a00000000007a70bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000001f777f10e1777100177e7710177777100177710
000000000000000000a0000000000700bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000177777100177710017777710177777100177710
00000000000000000000000000000000bbbbbbbbbbbbbbbbbbbb3333bbbbbbbbbbbbbbbb00000000000000000011111000011100001111100011111000011100
c99c99ccc0000ccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9aa9aa9c009900cc0000000000000000000000000000000000000000000000000000000000000000000000000011011000011100001101100000000000000000
9aaaaa9c09aa90cc0000000000000000000000000000000000000000000000000000000000000000000000000177177100177710017717710000000000000000
29a4a92c09aa90cc0000000000000000000000000000000000000000000000000000000000000000000000000177777100177710017777710000000000000000
9aaaaa9c009900cc0000000000000000000000000000000000000000000000000000000000000000000000000177777100177710017777710000000000000000
9aa9aa9cc0000ccc00000000000000000000000000000000000000000000000000000000000000000000000001717171e0177110017e77710000000000000000
2992992ccccccccc00000000000000000000000000000000000000000000000000000000000000000000000001f777f10e1777100177e7710000000000000000
c22c22cccccccccc0000000000000000000000000000000000000000000000000000000000000000000000000011111000011100001111100000000000000000
__label__
bbbbbbbbbbbbbbbbbbccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbcccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbcccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbabbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbabbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbabbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbabbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbb3ccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbb3333333ccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbb3333333cccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbb3cccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb99b99bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb9aa9aa9bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb9aaaaa9bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb29a4a92bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbabbbbbbb9aaaaa9bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbabbbbbb9aa9aa9bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb2992992bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb22b22bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbabbbbbbbabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbabbbbbbbabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbb3ccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
3333333333ccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
333333333cccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
ccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
ccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
ccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
ccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
ccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
ccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
cccccccccccbbbbbbbbbbbbbbcccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
ccccccccccbbbbbbbbbbbbbbbbccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
ccccccccccbbbbbbbbbbbbbbbbccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
ccccccccccbbbbbbbbbbbbbbbbccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
ccccccccccbbbbbbbbbbbbbbbbccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
ccccccccccbbbbbbbbbbbbbbbbccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
ccccccccccbbbbbbbbbbbbbbbbccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
ccccccccccbbbbbbbbbbbb3333cccccccc3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
ccccccccccbbbbbbbb33333333cccccccc3333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
ccccccccccbbbbbbbbbbbbccccccccccccc3333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
ccccccccccbbbbbbbbbbbbbbbbccccccccccccccc3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
ccccccccccbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
ccccccccccbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
ccccccccccbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
ccccccccccbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
cccccccccc3bbbbbbbbbbbbbb3cccccccccccccccc3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
cccccccccc3333333333333333cccccccccccccccc3333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333
ccccccccccc33333333333333cccccccccccccccccc3333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333
ccccccccccccccccccccccccccccccccccccccccccccccccc3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3ccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbbb11b11bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbb1771771bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbb1771771bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccc
cccccccccccccccccccccccccccccccccccccccccccccccccc3bbbbbbbbbb1777771bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3cccccc
bccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbccccccccc3333333bbbb1717171bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333cccccc
bbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbccccccccc3333333bbb1f777f1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333ccccccc
bbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccc3bbb1777771bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3ccccccccccccc
bbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbb11111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccc
bbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccc
bbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccc
bbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccc
bbbccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccc3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3cccccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccc3333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333cccccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbbbbbbbbbbbbbbbccccccccc3333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333ccccccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbb7a7bbbbbbbbbbbbbbbbbbbbccccccccccccccc3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3ccccccccccccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7a7bbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccc3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3cccccccccccccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccc3333333333333333333333333333333333333333cccccccccccccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccc33333333333333333333333333333333333333ccccccccccccccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3cccccccccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbccccc
bbb33333333333333bbbbbbbbbbbbbbbbbbbbbbbbbb3333333cccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb3333333333333333bbbbbbbbbbbbbbbbbbbbbbbb3333333cccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb3cccccccccccccc3bbbbbbbbbbbbbbbbbbbbbbbb3cccccccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbccccccccccccccc3bbbbbbbbbbbbbbbbbbbbbb3ccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbccccccccc333333333333333333333333ccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbccccccccc3333333333333333333333cccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbcccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbcccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbccccccccbbbbbbbbbb7bbbbbbb7bbbbbbbbbbbbbbbbbbbbbccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbbbbb
bbbbbbbbbbbbbbbbbbccccccccbbbbbbbbb7a7bbbbb7a7bbbbbbbbbbbbbbbbbbbbccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7a7bbbbbbbbbb
bbbbbbbbbbbbbbbbbbccccccccbbbbbbbbbb7bbbbbbb7bbbbbbbbbbbbbbbbbbbbbccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbbbbb
bbbbbbbbbbbbbbbbbbccccccccbbbbbbbbbbbbb7bbbbbbb7bbbbbbbbbbbbbbbbbbccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbb
bbbbbbbbbbbbbbbbbbccccccccbbbbbbbbbbbb7a7bbbbb7a7bbbbbbbbbbbbbbbbbccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7a7bbbbbbb
bbbbbbbbbbbbbbbbbbccccccccbbbbbbbbbbbbb7bbbbbbb7bbbbbbbbbbbbbbbbbbccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbb
bbbbbbbbbbbbbbbbbbccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7a7bbbbbbbbbbbbbbbbbb

__gff__
0000500016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010408101817018170181701817018170181701817018170181721817018172181701817218170181721817018102181001810218100181021810018102181001810218100181021810018102181001810218100
01040c181837018370184701847018470184701847218470184701847018470184701847018472184701847218470184721847018472184701847218470184720040000400004000040000400004000040000400
01040c181837018370184701847018470184701847218470184701847018470184701847018472184701847218470184721847018472184701847218470184720040000400004000040000400004000040000400
0107000c1807118072180611806218051180521806118062180711807218061180621805118052180611806200000000010000100001000010000100001000010000100001000010000100001000010000100001
010504081806018570185701857018572185701857218570005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011400000e0500e02515050150250e0500e02515050150250e0500e02515050150250e0500e02515050150250e0500e02515050150250e0500e02515050150250e0500e02515050150250e0500e0251505015025
011400000e0500e02515050150250e0500e02515050150250e0500e02515050150250e0500e025150501502513050130251a0501a02513050130251a0501a02513050130251a0501a02513050130251a0501a025
011400001e8401e8311e8211e8111e8151e8051c8401c8211e8401e8311e8211e8111e8151e805218402182123840238312382123811218402183121821218111a8401a8311a8211a8111a815008000080000800
011400001584015831158211784017831178211a8401a8311a8211a8101a8401a8211a8401a82119840198211584015831158211a8401a8311a8211c8401c8311c8211c8101c8151a8001a8001a8010080000800
0114000007050070250e0500e02507050070250e0500e02507050070250e0500e02507050070250e0500e0250e0500e02515050150250e0500e02515050150250e0500e02515050150250e0500e0251505015025
011400001e8401e8311e8211e8111e8151e8051c8001c8011e8401e8311e8211e8111e8151e8051c8001c80123840238312382123811218402183121821218112384023831238212381121840218312182121811
010a00201306301043306151a605306151a605306150e6053762037625306150e605306151a60513063010433061530605306150e6051306301043306150e6053762037625306150e605306151a605306150e605
010a00103c61530605306150e605306151a605306150e6053761037615306150e605306151a605306150e60500000000000000000000000000000000000000000000000000000000000000000000000000000000
010a00000743007411074300741107415004000743007411074300741107415004000743007411074300741107415004000743007411074300741107415004000743007421074110741507430074210741107415
010a00001e2301e2111e2301e2111e215182001e2301e2111e2301e2111e215182001e2301e2111e2301e2111e215182001e2301e2111e2301e2111e215182001f2301f2211f2111f2151f2301f2211f2111f215
010a00001e2301e2111e2301e2111e215002001e2301e2111e2301e2111e215002001e2301e2111e2301e2111e215002001e2301e2111e2301e2111e215002002323023221232112321523230232212321123215
010a00000943009411094300941109415004000943009411094300941109415024000943009411094300941109415024000943009411094300941109415024000943009421094110941509430094210941109415
010a00001e2301e2111e2301e2111e215002001e2301e2111e2301e2111e215002001e2301e2111e2301e2111e215002001e2301e2111e2301e2111e215002001c2301c2211c2111c2151c2301c2211c2111c215
010a00002123021211212302121121215002002123021211212302121121215002002123021211212302121121215002002123021211212302121121215002002123021230212212122021211212102121021215
010a0020021300211102160021110210009100021600211102160021110d1000e1000216002111021300211102100021010216002111021300211102100021010216002111021600211109160091110916009111
0114000007050070250e0500e02507050070250e0500e02507050070250e0500e02507050070250e0500e02509050090251005010025090500902510050100250905009025100501002509050090251005010025
011400001584015831158211784017831178211a8401a8311a8211a8101a8401a8211a8401a82119840198211984019831198211a8401a8311a8211c8401c8311c8211c8101c8151e60530610246152461518615
011400101a1351a1351a1351a1351a1351a13519135191351913519135191351a1351a1351a1351a1351a1351f1051f1051f1051f1051f1051f1051e1051e1051e10500100001000010000100001000010000100
010a002007130071110716007111071000e100071600711107160071111210013100071600711107130071110710007101071600711107130071110710007101071600711107160071110e1600e1110e1600e111
011400001890000000000000000000000000000000000000189000000000000000000000000000000000000018900000000000000000000000000000000000001890000000000002190015900159401a9401c940
011400001e9401e9311e9211e9201e9111e9101e915050001e5201e5201e5201e5111e5101e5101e515050001e5201e5201e5111e5101e5101e5151e505050001e5101e5101c9401c9311c9211c9102194021921
011400002394023931219402193121921219111a9401a9311a9211a9201a9111a9101a9150000021520215112352023511215202152021511215101a5201a5201a5111a5101a5100c62515900159301a9301c930
011400001e9401e9311e9211e9201e9111e9101e915050001e5201e5201e5201e5111e5101e5101e515050001e5201e5201e5111e5101e5101e5151c9401c9312394023931239212391021940219312192121910
011400001a9401a9311a9211aa401aa311aa211994019931199211991019a4019a31159401593117940179311a9401a9311a9211aa401aa311aa211c9401c9311c9211c9111c9101c9151c5001c5011c5001c505
0114002007135071450710007165071450e1000716507135071000716507135131000716507145071650714509135091450910009165091451010009165091350910009165091351510009150091310912109111
011400101a1351a1351a1351a1351a1351a135191351913519135191351913519135191201911119115191001f1051f1051f1051f1051f1051f1051e1051e1051e10500100001000010000100001000010000100
010a00001ec401ec401ec311ec301ec211ec201ec201ec111ec101ec101ec101ec1518c0018c0018c0018c001ec401ec401ec311ec301ec211ec201ec201ec111ec101ec101ec101ec1518c0018c0018c0018c00
010a000023c4023c4023c3123c3021c4021c4021c3121c3021c2121c2021c1121c101ac401ac401ac311ac3023c4023c4023c3123c3021c4021c4021c3121c3021c2121c2021c1121c101ac401ac401ac311ac30
010a000023c4023c4023c3123c3021c4021c4021c3121c3021c2121c2021c1121c101ac401ac401ac311ac3023c4023c4023c3123c3021c4021c4021c3121c3021c2121c2021c1121c1021c151ac001ac0126c00
011400000eb000eb110eb210eb310eb310eb310eb310eb310eb310eb310eb310eb310eb310eb310eb310eb310bb3107b3107b3107b3107b3107b3107b3107b3107b3107b3107b3107b3107b2107b1107b1507b05
0114000010b0010b1110b2110b3110b3110b3110b3110b3110b3110b3110b3110b3110b3110b3110b3110b310fb310eb310eb310eb310eb310eb310eb310eb310eb310eb310eb310eb310eb210eb110eb150eb05
0114000015b0015b1115b2115b3115b3115b3115b3115b3115b3115b3115b3115b3115b3115b3115b3115b3114b3113b3113b3113b3113b3113b3113b3113b3113b3113b3113b3113b3113b2113b1113b1513b05
011400001ab141ab211ab311ab311ab311ab311ab311ab3119b3119b3119b3119b3119b3119b3119b3119b311ab311ab311ab311ab311ab311ab311ab311ab3119b3119b3119b3119b3119b2119b1119b1519b05
011a00001ec401ec311ec211ec111ec151ec051cc401cc211ec401ec311ec211ec111ec151ec0521c4021c2123c4023c3123c2123c1121c4021c3121c2121c111ac401ac311ac211ac111ac1500c0000c0000c00
0114000021500215002350023500215002150021500215001a5001a5001a5001a5001a5000c60021520215112352023511215202152021511215101a5201a5201a5111a5101a5150c60500000000000000000000
010a00002b6102b615306050e605306150e605306150e6052b6102b615306050e605306151a605306050e6052b610286102461500000000000000000000000002b610246111f6111861118611186150000000000
011400200254010540155401a5400254010540155401a5400254010540155401954002540105401554019540075400e540155401a540075400e540155401a5400954010540155401954009540105401554019540
012800001ec401ec311ec211ec111ec151ec051cc401cc2123c4023c3123c2123c1121c4021c3121c2121c111ec401ec311ec211ec111ec151ec0521c4021c211ac401ac311ac211ac1119c4019c3119c2119c11
012800000c6040c600186041860024604246012d6042d6012b604286042b6041860437604286042b6040000407604076000c6040c600136041360000604006000c6140c610186141861024614246112f6142f611
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011400001861118611156111561110611106110c6110c611096110961104611046110061100611006010060500000000000000000000000000000000000000000000000000000000000000000000000000000000
014000080062000621096211762117621096210062100621000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0103000021614210202d0011a50016500235000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
010400000e5300e511155501551121550215112655026511265150050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
010600001a040230011e5011a50016500235000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
01030000150330e0230c6150000507605000050060500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
010400001602318610136150c605186052b6042b60500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005217031570302703
010400001a5501a511215502151121515005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
__music__
03 397a4e44
00 797a4e44
00 797a4e44
00 2c386768
01 2c2d2e44
00 10114f44
00 13145044
00 10120f44
00 13150f44
00 0e191644
00 0e1b1a19
00 0e1c1619
00 0e1d1a19
00 0e1e1619
00 0e1f2019
00 0e101119
00 0e131419
00 0e101219
00 0f131521
00 0e1c1619
00 0e1d1a19
00 0e1e1619
00 0e1f2021
00 0e101159
00 0e131459
00 0e101122
00 0e131423
00 0f101222
00 2b131524
00 2c666868
02 2c286768
00 6a666769

