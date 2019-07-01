;;;;;;;;;;;;;;;;;
;;; Interface ;;;
;;;;;;;;;;;;;;;;;

;n_bw = number of bird watchers
;n_p = number of pleasurers
;n_np = number of bosses of a national park
;n_nh = number of bosses of the neighborhood
;n_ns = number of non-selfish people
;startchyg = container hygiene after cleaning

breed [birdwatchers birdwatcher]
breed [pleasurers pleasure]
breed [natparks natpark]
breed [neighbosses neighboss]
breed [nonselfs nonself]

turtles-own
[ ;; static
  values
  a ; altruistic
  b ; biospheric
  eg ; egoistic
  h ; hedonic
  NEP ; New Environmental Paradigm
  AwoC ; Awareness of Consequence
  AscoR ; Ascription of Responsibility

  ;; dynamic
  herkenningbio ;; recognition of biowaste
  willwalk ;; willingness to walk
  cexp ;; container experience
  cdisp ;; container disposal
  l_storage ;; kg of biowaste in local bin
  last_time_success ;; subjective view on disposal experience
  bioknow ;; knowledge about bio-waste separation
  contdist ;; willing distance to walk to nearest container
  positive ;; positive feeling about the symbiotic network (yes/no)
  symbhappiness ;; overall happiness about the symbiotic network (numerical)
  ]


globals
[ day
  yesterday
  num-nodes
  duration
  non_sorted_bio
  sorted_bio
  l_storage_max
  l_hygiene
  c_storage
  c_storage_max
  c_hygiene
  schedule
  mcapacity
  mtechnology
  distcmax ; maximum distance to a container in Amsterdam
  totsymbhappiness ; number of turtles positive about symbiotic network
  cdist
  counttrue
  countfalse
  newsimpact
  tcdisp
  tcexp
  therkenning
  twillwalk
]

;;;;;;;;;;;;;;;;;;;;;;;;
;;; Setup Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

to setup-globals
  set num-nodes n_bw + n_p + n_np + n_nh + n_ns
  set duration 5 * 7 * 25  ;; 5 times to the waste bio-waste-bin a day, for 25 weeks
  set non_sorted_bio 0
  set sorted_bio 0
  set l_storage_max 200 ;; 200 kg of bio-waste
  set c_storage 0
  set c_storage_max 1500
  set c_hygiene startchyg
  set schedule startschedule
  set mcapacity True
  set mtechnology True
  set distcmax 800
  set totsymbhappiness 0.1
  set newsimpact 0.005 * n_ns ;; 2 non_selfish = 2% growth


  ;; policies
  ;if policies = "off" [
   ; set newsletter False set feedback False set humanengmt False set ondemand False set group False]
  if policies = 1 [
    set newsletter False set feedback True set humanengmt False set ondemand False set group False]
  if policies = 2 [
    set newsletter False set feedback False set humanengmt False set ondemand False set group True]
  if policies = 3 [
    set newsletter False set feedback False set humanengmt False set ondemand True set group False]
  if policies = 4 [
    set newsletter True set feedback False set humanengmt False set ondemand False set group False]
  if policies = 5 [
    set newsletter False set feedback False set humanengmt True set ondemand False set group False]
  if policies = "all" [
    set newsletter True set feedback True set humanengmt True set ondemand True set group True]
  if policies = 13 [
    set newsletter False set feedback True set humanengmt False set ondemand True set group False]
  if pps != "off"[
    set schedule round (150 / num_people) set startschedule round (150 / num_people)]
  if pps = "off"[
    set startschedule 15 set schedule startschedule]


end

to make-turtles
  ;; arrange them in a circle in order by who number

  create-birdwatchers n_bw [
    set a 0
    set b 1
    set eg 0
    set h 1
    set color yellow]
  create-pleasurers n_p[
    set a 0
    set b 0
    set eg 0
    set h 1
    set color pink]
  create-natparks n_np [
    set a 0
    set b 1
    set eg 1
    set h 0
    set color green]
  create-neighbosses n_nh [
    set a 0
    set b 1
    set eg 1
    set h 1
    set color blue]
  create-nonselfs n_ns[
    set a 1
    set b 1
    set eg 1
    set h 0
    set color red]

   ;; people scenario's
  if pps = 1 [
    ask birdwatchers [die] create-birdwatchers num_people [set b 1 set color yellow] ]
  if pps = 2 [
    ask pleasurers [die] create-pleasurers num_people [set b 0 set color pink] ]
  if pps = 3 [
    ask natparks [die] create-natparks num_people [set b 1 set color green] ]
  if pps = 4 [
    ask neighbosses [die] create-neighbosses num_people [set b 1 set color blue] ]
  if pps = 5 [
    ask nonselfs [die] create-nonselfs num_people [set b 1 set color red]  ]


  ask turtles[ set size 2.5]
  layout-circle (sort turtles) max-pxcor - 2


;;; Create personal norms based on questionnaire
  ask turtles[
    set AwoC random-normal 0.7 0.104
    set AscoR random-normal 0.5 0.215]

;;; Setup humans beliefs and their local waste bins.
  ask turtles [
   set contdist round(0.3 * distcmax + 0.7 * (random distcmax + 1))
    ifelse b = 1 [
      set NEP (random-normal 0.8 0.15)
      set bioknow (2 + (random 8)) / 10 ;; set to NEP
      set contdist min (list (contdist + 0.25 * contdist) distcmax)]
     [
      set NEP (random-normal 0.6 0.15)
      set bioknow random 10 / 10] ;; set to NEP
    set l_storage 0
    set l_hygiene True
    set cexp True
    set cdisp True
    set symbhappiness 0.1
    set positive False

  ]

end


to setup
  clear-all
  reset-ticks
  set-default-shape turtles "circle"
  setup-globals
  make-turtles
    ;;error prevention
  if count turtles <= 0 [print "No turtles to run simulation" stop]
  if num_links > num-nodes [print "I cannot talk to that many people" stop]
    ;;
  set cdist (mean [contdist] of turtles)
  ask patches[
    set pcolor 69.9]
end
;;;;;;;;;;;;;;;;;;;;;;;
;;; Main Procedure ;;;
;;;;;;;;;;;;;;;;;;;;;;;

to go
  if ticks = duration [ stop]
  if sum [contdist] of turtles != 0 [set cdist (mean [contdist] of turtles)]
  set totsymbhappiness sum [symbhappiness] of turtles

  ;; individual behaviour

  ask pleasurers[
    RecognitionBio
    hygiene_check
    WillingnessToWalk
    SubjExperienceCont
    DisposalCap ]

  ask birdwatchers [
    RecognitionBio
    hygiene_check
    WillingnessToWalk
    SubjExperienceCont
    DisposalCap
    positivefeeling ] ;; check how the project is coming along

  ask natparks [
    RecognitionBio
    hygiene_check
    WillingnessToWalk
    SubjExperienceCont
    DisposalCap
    positivefeeling ];; check how the project is coming along


  ;; effects of time
  set c_hygiene c_hygiene - 1
  ask turtles [loseinterest]

  set day floor (ticks / 4)
  if yesterday != day [
    ask neighbosses [setsocialnorms]
    ask n-of (0.01 * num_readers * (count turtles)) turtles [ReadNews]]
  set yesterday day

  socialbehaviour
  techbehaviour

  ;; municipal behaviour
  if ondemand = False [
    if ticks - schedule = 0 [
      municipalsortation
      set schedule schedule + startschedule ]]

  if ondemand = True [
    if ticks - schedule = 0 [set c_hygiene random-normal (startchyg - (startchyg / 3)) (startchyg / 10) set schedule schedule + startschedule]
    if ceiling c_storage >= c_storage_max [
      municipalsortation]]

  ;; scenario death
  if leaving = True [
    if ticks = (round (0.5 * duration)) [
      ask one-of neighbosses [set color white die]
      ask turtles [
      set herkenningbio False set willwalk False set cexp False (set bioknow min (list 0.5 (bioknow))) set newsimpact (0.75 * newsimpact)]]]

  if count turtles < n_ns + n_nh + n_p + n_bw + n_np [
   ask turtles [
    set contdist round(0.3 * distcmax + 0.7 * (random distcmax + 1))
    set symbhappiness 0  ]]

  ;; discharge
  ask pleasurers[
    Discharge-Waste-Local
    discharge-waste-container]
  ask birdwatchers[
    Discharge-Waste-Local
    discharge-waste-container]
  ask natparks[
    Discharge-Waste-Local
    discharge-waste-container]


  clear-links
  tick

end

;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SETUP OWN BEHAVIOR ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;


to RecognitionBio
; The recognition and successful sortation of bio-waste is dependent on:
; time and reachability of the local bin
; Bio-recylcing knowledge
; Environmental attitude of the actor.

  ifelse b = 1 [
     ifelse random 100 < 75[
      set herkenningbio True] [set herkenningbio False]]
    [ ifelse random 100 < 60 [ ;; random function to represent the time and reachability of the local bin
      set herkenningbio True][
        set herkenningbio False ] ]
  if bioknow > 0.70 [ set herkenningbio True] ;; AANNAME you need to hear something 7 times before it sticks


end

to WillingnesstoWalk
;The willingness to walk to the container is dependent on:
; the distance to the container
; the time it takes to get there (time * distance could make the random value, see below )
; biospheric values of the actor.
    ;; A random container is placed at every step, to include the time variable and the randomness of people's
  ifelse ((random 100) / 100) * distcmax < contdist [ ;; is the nearest container in my walkable range?
    set willwalk True] ;; if yes, walking distance is ok
  [set willwalk False]

  if willwalk = False [ if (bioknow > 0.5) or (symbhappiness > 0.5) [ if random 100 < 80 [set willwalk True]]]


end

to SubjExperienceCont
 ;The subjective experience of bio-waste containers is dependent on:
 ; the safety
 ; the hygiene
 ; the social atmosphere of the container.
  ifelse cexp = True [ ;; Question how the experience was last time.
    ifelse random 100 > 20 [ ;; If positive, it will most likely be positive again/
      ifelse c_hygiene > 0.5 * startchyg [ set cexp True ]
      [ifelse random 10 < 5 [ ;;if container hygiene is clean, more chance on bad experience
        set cexp True]
        [set cexp False]]]
    [set cexp False] ]


  [ ifelse random 100 > 20 [ifelse c_hygiene > 0.5 * startchyg
      [ set cexp True ][
      ifelse random 10 > 4 [
        set cexp True][set cexp False ]]] [set cexp False]]



end

to DisposalCap
 ;The disposal capability in the bio-waste containers is dependent on:
 ;the capacity of the container
 ;and the ease of container interaction.
  ifelse c_storage < c_storage_max[ ;; container capacity
    ifelse random 100 < 98 [ ;; container too difficult to interact with 2% of the time
      set cdisp True][set cdisp False]] [set cdisp False]


end


;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; BIO-WASTE BEHAVIOUR ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

to hygiene_check
  ;; roughly every other month the bin is too smelly and should be emptied earlier than normal
  if random (num-nodes * 100) >= ((num-nodes * 100) - (0.5 * num-nodes)) [ ;; f.e. random 1900 <= 1891
    set l_hygiene False]
end

to Discharge-Waste-Local
  ;Local waste is separated in the local bin if agents are positive about the network or if the agent recognises the waste.
  if herkenningbio = False [set therkenning therkenning + 1]
  ifelse herkenningbio = True or positive = True [ ;; you will either recognize the waste, or you will put in more efforts because of your positive attitude
        set l_storage l_storage + random-normal 21.9 2.8 ; based on research Waste Transformers
  ] [set non_sorted_bio (non_sorted_bio + random-normal 21.9 2.8)] ;; unrecognized without a positive symbiotic network means unsorted + 1

end

to Discharge-Waste-Container
  ;Individuals want to separate their local waste to a central bin when the bin is full or smelly.
  ;If they are willing to walk the distance, are okay with the experience and if there is a disposal possibility and the container storage rises by the amount in the bin.

  if l_storage >= l_storage_max or l_hygiene = False [
        ifelse (willwalk = True) and (cexp = True) and (cdisp = True) [
          set c_storage (c_storage + l_storage)
          set l_storage 0
          set l_hygiene True
          set cexp True]

    [ set non_sorted_bio (non_sorted_bio + l_storage)
      set l_storage 0
      set l_hygiene True
      set cexp False

          ] ]

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; MUNICIPAL BEHAVIOUR ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

to municipalsortation
  ;To measure the sorted and non-sorted bio-waste in the area the central containers are emptied and that results to the final quantity of sorted bio-waste.
  if sorted_bio > 5 * non_sorted_bio [set mcapacity False set mtechnology False print "This is too much for me" ask turtles [die]]

  ifelse mcapacity = True and mtechnology = True [
    set sorted_bio (sorted_bio + c_storage)
    set c_storage 0] [
    set non_sorted_bio (non_sorted_bio + c_storage)]

  set c_hygiene random-normal (startchyg - (startchyg / 3)) (startchyg / 10)

end

;;;;;;;;;;;;;;;;;;;;;;;;;
;;; EFFECTS OVER TIME ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;

to loseinterest
  ;; roughly every other month people lose some interest
  if random (num-nodes * 100) >= ((num-nodes * 100) - (0.5 * num-nodes)) [
     if symbhappiness < 0.5 or positive = False [
      set bioknow max (list 0 (bioknow - (0.3 * random-float bioknow))) stop]
     if symbhappiness > 0.5 or positive = True [
      set bioknow max (list 0 (bioknow - (0.1 * random-float bioknow))) stop]]
    ;; AANNAME
end

to ReadNews
  ;; impact of newsletter policy
  if Newsletter = True [
      set bioknow min (list 1 (bioknow + newsimpact))

  set bioknow (bioknow - (0.5 * newsimpact / (875))) ]
end

to positivefeeling
  ;; creation of positivity
  ifelse non_sorted_bio != 0 [
    ifelse feedback = True [ ;; if the turtle knows about the results of the model
      ifelse sorted_bio / (sorted_bio + non_sorted_bio) > (0.8 - ((AwoC + AscoR) / 2))[ ;; interest linked to your awareness and responsibility
      set positive True  ]
      [set positive False]]
    [set positive False]] ;; get a positive attitude
  [set positive False]

  if positive = True [
    set contdist min (list(contdist + (0.1 * random contdist)) (distcmax))
    set bioknow min (list 1 (bioknow + (0.5 * newsimpact))) ]

end

to setsocialnorms
  ;; the creation of links by the Type D agent.
  if num_links = 0 [stop]
  if pleasurers != 0 [create-links-with n-of round (0.1 * num_links * count pleasurers) pleasurers]
  if birdwatchers != 0 [create-links-with n-of round (0.1 * num_links  * count birdwatchers) birdwatchers]
  if natparks != 0 [create-links-with n-of round (0.1 * num_links * count natparks) natparks ]
  if group = False and in-link-neighbors != 0 [ ask one-of in-link-neighbors [set herkenningbio True set willwalk True set cexp True ]]
  if group = True and in-link-neighbors != 0[ ask in-link-neighbors [set herkenningbio True set willwalk True set cexp True set symbhappiness min (list 1 (symbhappiness + random-normal 0.002 0.001  )) ]]

end

to socialbehaviour
  ;; update numerical symbiotic happiness with yes/no positivity.
  ask turtles[
    ifelse positive = true [ set symbhappiness min (list 1 (symbhappiness + random-normal 0.001 0.005)) ]
    [set symbhappiness min (list 1 (symbhappiness + random-normal 0.0004 0.004 )) ] ]

end

to techbehaviour
  ;; impact of the Human Engagement policy on the container display and experience
ask turtles [
if HumanEngmt = True [if random 100 < 80 [ifelse random 100 < 50 [set cdisp True] [set cexp True]]]]
end
@#$#@#$#@
GRAPHICS-WINDOW
510
12
726
229
-1
-1
5.943
1
10
1
1
1
0
0
0
1
-17
17
-17
17
0
0
0
ticks
30.0

BUTTON
323
13
389
46
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
323
57
389
90
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
18
16
92
61
NIL
sorted_bio
1
1
11

MONITOR
733
16
790
61
NIL
ticks
17
1
11

MONITOR
735
69
792
114
NEP
mean [NEP] of turtles
2
1
11

MONITOR
734
124
791
169
AwoC
mean [AwoC] of turtles
2
1
11

MONITOR
735
177
792
222
AscoR
mean [AscoR] of turtles
2
1
11

PLOT
13
80
268
247
Biowaste
NIL
NIL
0.0
700.0
0.0
10.0
true
true
"" ""
PENS
"not sorted" 1.0 0 -2674135 true "" "plot non_sorted_bio"
"sorted" 1.0 0 -13840069 true "" "plot sorted_bio"

SLIDER
406
12
498
45
n_bw
n_bw
0
10
6.0
1
1
NIL
HORIZONTAL

SLIDER
406
45
498
78
n_p
n_p
0
10
6.0
1
1
NIL
HORIZONTAL

SLIDER
406
78
498
111
n_np
n_np
0
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
406
111
498
144
n_nh
n_nh
0
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
406
144
498
177
n_ns
n_ns
0
10
2.0
1
1
NIL
HORIZONTAL

MONITOR
106
16
217
61
Percentage sorted
sorted_bio / (sorted_bio + non_sorted_bio)
5
1
11

CHOOSER
406
184
498
229
startchyg
startchyg
100 200 300
1

SWITCH
620
335
747
368
Group
Group
1
1
-1000

MONITOR
264
368
365
413
Bio knowledge
mean [bioknow] of turtles
3
1
11

SWITCH
511
335
614
368
Feedback
Feedback
0
1
-1000

SWITCH
511
294
616
327
Newsletter
Newsletter
1
1
-1000

SWITCH
619
253
759
286
HumanEngmt
HumanEngmt
1
1
-1000

SWITCH
619
294
747
327
OnDemand
OnDemand
1
1
-1000

CHOOSER
511
241
603
286
policies
policies
"off" 1 2 3 4 5 "all" 13
0

SWITCH
511
377
615
410
Leaving
Leaving
1
1
-1000

SLIDER
310
202
402
235
num_links
num_links
0
10
2.0
1
1
NIL
HORIZONTAL

MONITOR
384
368
456
413
Symbiose
mean [symbhappiness] of turtles
3
1
11

SLIDER
623
378
795
411
num_readers
num_readers
0
100
100.0
5
1
%
HORIZONTAL

CHOOSER
406
292
501
337
pps
pps
"off" 1 2 3 4 5
0

SLIDER
273
292
395
325
num_people
num_people
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
294
249
466
282
startschedule
startschedule
0
100
15.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?
The Re-StOre project in de NDSM wharf includes many stakeholders, with a wide variety of opinions and goals, different technical aspects and natural uncertainties. These factors all have to be aligned in some sorts, for the waste processing to be an environmental success. The agents in the network behave in a dynamic and complex matter. This research uses Agent-based modeling (ABM) to model this environment, because ABM is a successful method to model complex behaviour (Macal & North, 2005). 

## WHERE DID THIS COME FROM?

From 2016 till 2018 the University of Applied Sciences in Amsterdam ran the project Re-Organise. Research was done on the decentralized processing of organic waste flows at urban farms. This project resulted in the design of several technical solutions and prototypes for corporate small-scale processing of organic residual flows at urban farming locations. The knowledge of the Re-Organise project is underlying the follow-up Re-StOre.

Since 2018, Re-StOre (2019) is developing a measuring system and simulation model that gives companies and municipalities more insight into the financial, ecological and social effects of various composting and biodigestion forms, on a small and large scale. The system must enable municipalities and businesses to make better choices on issues like “which solution for the processing of organic waste fits best in a specific situation”.

In light of this research, the NDSM wharf has emerged as a potential focal point on the topic of a symbiotic network for bio-waste processing. From the 1920s until the 1980s, the NDSM-wharf was one of the biggest shipyards in the world. Recently it has become a home port for creative pioneers.


## HOW IT WORKS

The model starts with the generation of bio-waste inflow. In their paper on the complexity of food waste behaviors Quested, Marsh, Stunell & Parry (2013) discuss the inflow of bio-based products and their process to bio-waste. The quantities here are based on the previously collected waste quantities of the businesses at the NDSM wharf.

Secondly the bio-waste sortation of the actor is called upon. The recognition and successful sortation of bio-waste is dependent on the time and reachability, the knowledge and biospheric values of the actor. Based on these values the bio-waste is collected in a local bin or thrown into the general waste. While the bio-waste storage bin has space and doesn’t smell, this process shall continue.

When the bin is ready to be centrally collected the actor has three factors to take into account: willingness to walk the distance, previous container experiences and difficulty of disposal. The first factor includes the distance to the container, the time it takes to get there and biospheric values of the actor. The second value includes the safety, the hygiene and the social atmosphere of the container. The third value includes the capacity of the container and the ease of container interaction.

Finally the bio-waste has (or has not) reached the central container. In accordance with the waste processor these will be emptied and the bio-waste is transformed from individually-owned bio-based product to centralized and sorted bio-waste outflow.  Lang, Binder, Scholz, Schleiss & Stäubli (2006) note three boundary conditions to the driving forces in centralized bio-waste transformation: Technological development, Environmental awareness, Processing capacity of the treatment facilities. In this model the environmental awareness is included in the profile-specific behavior of the actors. The remaining boundary conditions are bundled in one function of the ABM model to limit the abilities of the behavior space.  

Over time the interest of agents in the model start to reduce. They will be less willing to walk the distance to separate their green waste, rather they will fall back into behavior of non-separation. 



## CREDITS AND REFERENCES
S.I.M. Kerssens (2019)

You are free to:
 Share — copy and redistribute the material in any medium or format
 Adapt — remix, transform, and build upon the material for any purpose, even
 commercially. 

Under the following terms: 
 Attribution — You must give appropriate credit, provide a link  to the license, and
 indicate if changes were made. You may do so in any reasonable
 manner, but not in any way that suggests the licensor endorses you or your use.
 No additional restrictions — You may not apply legal terms or technological measures
 that legally restrict others from doing anything the license permits.

The software is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and noninfringement. In no event shall the authors or copyright holders be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the software.

 
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.2
@#$#@#$#@
setup
repeat 5 [rewire-one]
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="vary-rewiring-probability" repetitions="5" runMetricsEveryStep="false">
    <go>rewire-all</go>
    <timeLimit steps="1"/>
    <exitCondition>rewiring-probability &gt; 1</exitCondition>
    <metric>average-path-length</metric>
    <metric>clustering-coefficient</metric>
    <steppedValueSet variable="rewiring-probability" first="0" step="0.025" last="1"/>
  </experiment>
  <experiment name="First Experiment" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>sorted_bio</metric>
    <metric>non_sorted_bio</metric>
    <metric>c_storage</metric>
    <metric>mean [bioknow] of birdwatchers</metric>
    <metric>mean [bioknow] of pleasurers</metric>
    <metric>mean [symbhappiness] of birdwatchers</metric>
    <metric>mean [symbhappiness] of pleasurers</metric>
    <enumeratedValueSet variable="startchyg">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startschedule">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_links">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_p">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_ns">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_np">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_nh">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_bw">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policies">
      <value value="&quot;off&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pps">
      <value value="&quot;off&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="People" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>sorted_bio</metric>
    <metric>non_sorted_bio</metric>
    <metric>mean [bioknow] of turtles</metric>
    <enumeratedValueSet variable="startchyg">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_links">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_readers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policies">
      <value value="&quot;off&quot;"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pps">
      <value value="&quot;off&quot;"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_people">
      <value value="15"/>
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Real Waste" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>non_sorted_bio</metric>
    <metric>sorted_bio</metric>
    <metric>cdist</metric>
    <enumeratedValueSet variable="startchyg">
      <value value="100"/>
      <value value="200"/>
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_p">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_ns">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_np">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_nh">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feedback">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_bw">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="group">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Joke" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>non_sorted_bio</metric>
    <metric>sorted_bio</metric>
    <enumeratedValueSet variable="Group">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_p">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startchyg">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_ns">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_np">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_nh">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Feedback">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_bw">
      <value value="6"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="policies" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>sorted_bio</metric>
    <metric>non_sorted_bio</metric>
    <metric>mean [bioknow] of turtles</metric>
    <metric>mean [bioknow] of pleasurers</metric>
    <metric>mean [bioknow] of birdwatchers</metric>
    <metric>mean [symbhappiness] of turtles</metric>
    <metric>mean [symbhappiness] of birdwatchers</metric>
    <metric>mean [symbhappiness] of pleasurers</metric>
    <enumeratedValueSet variable="n_p">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_ns">
      <value value="2"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_bw">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startchyg">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_np">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_nh">
      <value value="1"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_links">
      <value value="1"/>
      <value value="2"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startschedule">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Leaving">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_readers">
      <value value="60"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policies">
      <value value="&quot;off&quot;"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Leaving" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>sorted_bio</metric>
    <metric>non_sorted_bio</metric>
    <metric>mean [bioknow] of turtles</metric>
    <metric>mean [symbhappiness] of turtles</metric>
    <enumeratedValueSet variable="n_p">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_ns">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_bw">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startchyg">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_np">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_nh">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_links">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startschedule">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Leaving">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policies">
      <value value="&quot;off&quot;"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="policies all" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>sorted_bio</metric>
    <metric>non_sorted_bio</metric>
    <metric>mean [bioknow] of turtles</metric>
    <metric>mean [symbhappiness] of turtles</metric>
    <metric>mean [bioknow] of pleasurers</metric>
    <metric>mean [bioknow] of birdwatchers</metric>
    <metric>mean [symbhappiness] of pleasurers</metric>
    <metric>mean [symbhappiness] of birdwatchers</metric>
    <metric>c_storage</metric>
    <enumeratedValueSet variable="n_p">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_ns">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_bw">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startchyg">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_np">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_nh">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_links">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startschedule">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policies">
      <value value="&quot;off&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Newsletter">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Feedback">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HumanEngmt">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OnDemand">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Group">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Leaving">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_readers">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pps">
      <value value="&quot;off&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="policies total check" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>sorted_bio</metric>
    <metric>non_sorted_bio</metric>
    <metric>mean [bioknow] of turtles</metric>
    <metric>twillwalk</metric>
    <metric>tcexp</metric>
    <metric>tcdisp</metric>
    <metric>therkenning</metric>
    <enumeratedValueSet variable="n_p">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_ns">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_bw">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startchyg">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_np">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_nh">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_links">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startschedule">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Leaving">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policies">
      <value value="&quot;off&quot;"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="People policies" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>sorted_bio</metric>
    <metric>non_sorted_bio</metric>
    <metric>mean [bioknow] of turtles</metric>
    <metric>mean [symbhappiness] of turtles</metric>
    <enumeratedValueSet variable="n_p">
      <value value="6"/>
      <value value="320"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startchyg">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_ns">
      <value value="1"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_np">
      <value value="5"/>
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_nh">
      <value value="2"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policies">
      <value value="&quot;off&quot;"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_bw">
      <value value="6"/>
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startschedule">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_links">
      <value value="2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="No policies" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>sorted_bio</metric>
    <metric>non_sorted_bio</metric>
    <enumeratedValueSet variable="Group">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HumanEngmt">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_p">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_ns">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Newsletter">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Feedback">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policies">
      <value value="&quot;off&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_people">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_bw">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OnDemand">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startchyg">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_np">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_nh">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_links">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_readers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pps">
      <value value="&quot;off&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startschedule">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Leaving">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="people 13" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>sorted_bio</metric>
    <metric>non_sorted_bio</metric>
    <enumeratedValueSet variable="HumanEngmt">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Group">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_p">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_ns">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Newsletter">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Feedback">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policies">
      <value value="13"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_people">
      <value value="15"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_bw">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OnDemand">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startchyg">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_np">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_nh">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_readers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_links">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pps">
      <value value="&quot;off&quot;"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startschedule">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Leaving">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
