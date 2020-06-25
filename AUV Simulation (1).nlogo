breed [fishes fish]
breed [AUVs AUV]

globals
[
  the-fish
  the-AUV
  sea-colour
  deep-sea-colour
  the-deep-sea
  AUV-base-0-x AUV-base-0-y
  AUV-base-1-x AUV-base-1-y
  fish-outside-tracking-area?
  AUV-outside-tracking-area?
  AUV-returned-to-home?
  AUV-arrived-base-1?




]

patches-own [ depth]
fishes-own [ direction]



; INITIALIZATION SETUP
to setup

  ; Sets up the fish, AUV and environment.

  clear-all
  setup-AUV
  setup-fish
  setup-environment
  reset-ticks
end


to setup-AUV
  ;Sets up the AUV

  set AUV-outside-tracking-area? false
  set AUV-arrived-base-1? false
  set AUV-returned-to-home? false

  set AUV-base-0-x 14
  set AUV-base-0-y -55

  set AUV-base-1-x 25
  set AUV-base-1-y 50

  create-AUVs 1
  [
    set the-AUV self
    setxy AUV-base-0-x AUV-base-0-y
    set size 10
    set pen-size 1
    pen-down
    ;set shape "robot"
    set color magenta
    set heading 340
  ]

end

to setup-fish


  set fish-outside-tracking-area? false
  create-fishes 1
  [

    set the-fish self
    setxy 10 -48
    set size 7
    ;set pensize 1.4
    ;pen-down
    ;set shape "fish 1"
    set color gray
    set heading 0

    ifelse random 2 = 0
    [set direction 1]
    [set direction -1]

    set direction 1
    if (direction = 1)
    [set heading 25]
  ]
end

to setup-environment
; Loads the environment from the map image.

  let py min-pycor + 4
  let px 0

  import-pcolors "Rhyl1.png"

  set sea-colour blue + 3
  set deep-sea-colour blue + 2
  set the-deep-sea 22

  while [py < max-pxcor]
  [
    set px min-pxcor
    while [px <= max-pxcor]
    [
      ask patch px (py - 4)
      [ set pcolor [pcolor] of patch px py ]
      set px px + 1
    ]
    set py py + 1
  ]

  ask patches with [pycor > 62]
  [ set pcolor sea-colour ] ; colour upper part of environment to the sea
  ask patches with [pxcor < -217]
  [ set pcolor sea-colour ] ; colour left part of environment to the sea

  ask patches with [(pxcor > -199 and pxcor < -186) and (pycor > -105 and pycor < -92)]
  [ set pcolor sea-colour ] ; colour pointer to the sea

;  ask patches with [(pcolor < 29.5 and pcolor > 28.0) or (pcolor = 38.7)]
;  [ set pcolor blue + 4 ] ; colour mudflat area

  ask patches with [(pcolor < 99.5 and pcolor > 98.5)]
  [ set pcolor sea-colour ] ; colour the sea
;  ask patches with [((pcolor > 97.5 and pcolor < 98.5) or (pcolor > 85.5 and pcolor < 87.8)) and (pxcor < 129) and (pycor > -155)]
;  [ set pcolor magenta ] ; get rid of map grid
  ask patches with [(pcolor = 84.9) and (pxcor = 130) and (pycor > -27)]
  [ set pcolor sea-colour ] ; get rid of map grid
;  ask patches with [(pcolor = 96.7) and (pxcor = 130) and (pycor > -27)]
;  [ set pcolor magenta ] ; get rid of map grid
;  ask patches with [(pcolor = 89.2) or (pcolor = 89.3)]
;  [ set pcolor orange ] ; get rid of map grid

  ask patches with [(pcolor < 89.5 and pcolor > 84.5) and (pycor != -30)]
  [ set pcolor sea-colour ] ; colour odd bits at edges of marsh as the sea
  ask patches with [(pcolor < 96.5 and pcolor > 94.5)]
  [ set pcolor sea-colour ] ; colour odd bits at edges of marsh as the sea

  ask patches with [(pcolor != sea-colour) and (length (filter [ ?1 -> ?1 = sea-colour ] [pcolor] of neighbors) >= 3)]
  [ set pcolor sea-colour ] ; colour odd bits in rest of the sea

;  ask patches with [(pcolor != 29) and (length (filter [? = 29] [pcolor] of neighbors) >= 3)]
;  [ set pcolor sea-colour ] ; colour odd bits in mudflats

  ask patches with [(pcolor = sea-colour) and ((pxcor > 280) or (pxcor < -280) or (pycor > 170) or ((pycor < -170) and (pxcor < -170)))]
  [ set pcolor deep-sea-colour ] ; mark the deep blue sea which the robot is not allowed to move out off

  ; set the depth of the sea
  ask patches with [pcolor = sea-colour or pcolor = deep-sea-colour]
  [
    ifelse (pycor < -60) and (pxcor < -34)
      [ ; bottom left corner
        set depth 5 + (pycor - min-pycor) / 10
        if (depth < 8)
          [ set depth 8 ]
      ]
      [ set depth 1 + (pycor - min-pycor) / 10 ]

;    if-else (count patches in-radius 15 with [(pcolor != sea-colour) and (pcolor != deep-sea-colour)] > 0)
;      [ set depth 1 + pycor / 10 ]
;      [
;        set depth 10 + (distance patch 26 20) / 10
;      ]
  ]

;  ask patches with [pcolor = deep-sea-colour]
;  [
;    set depth 45 + random 10 - random 10
;  ]

;  check depth
;  ask patches with [pcolor = sea-colour or pcolor = deep-sea-colour]
;  [ set pcolor scale-color blue depth 0 50 ]
end


; INITIALIZATION GO

to go

  ask fishes
  [
    go-fish
  ]
  ask AUVs
  [
    go-AUV
  ]
  if (AUV-returned-to-home?)
  [stop]
  tick
end

to go-fish ;fish procedure that defines the behaviour of the fish every tick

  fish-head-randomly

  let fish-behaviours
  [ "Stationary" "go-fish-stationary"
    "Random" "go-fish-random"
    "Follow coastline" "go-fish-follow-coastline"
    "Deeper" "go-fish-deeper"
    "Deeper random" "go-fish-deeper-random" ]
  let p position fish-behaviour fish-behaviours
  run (item(p + 1) fish-behaviours)
end

to go-AUV
  let AUV-behaviours
  [ "Stationary" "go-AUV-stationary"
    "Follow fish" "go-AUV-follow-fish" ]
    let p position AUV-behaviour AUV-behaviours
    run (item(p + 1) AUV-behaviours)
end

; FISH BEHAVIOURS

to go-fish-stationary
; Fish behaviour: Do nothing.

end

to go-fish-follow-coastline
; Fish behaviour: Follow the coastline where possible.

  if (random 100 >= feed-percentage)
    [
      fish-outside-tracking-area

      if (not avoid-coastline? 5)
        [ fd fish-speed ]
    ]
end

to fish-outside-tracking-area
; Checks whether the fish has reached the outside tracking area.

  if (outside-tracking-area?)
    [ set fish-outside-tracking-area? true
      output-print "Fish has gone outside tracking area!"
      die ]
end

to fish-head-deeper ;; fish turtle procedure
; Fish heads to deeper to ocean.

  let next-patch max-one-of neighbors [depth]
  set heading towards next-patch
end

to go-fish-deeper
; Fish behaviour: Heads further into the ocean

  if (not avoid-coastline? 90)
    [ fish-outside-tracking-area ]

  fish-head-deeper
  fd fish-speed
end

to go-fish-deeper-random
; Fish behaviour: Heads further into the ocean
; the deep sea as defined by the variable the-deep-sea.

  if (not avoid-coastline? 90)
    [ fish-outside-tracking-area ]

  ifelse (depth >= the-deep-sea)
    [ fish-head-randomly ]
    [ fish-head-deeper ]

  fd fish-speed
end

to go-fish-random
; Fish behaviour: Same as the procedure go-fish-deeper-random above for the time being.

  if (not avoid-coastline? 90)
    [ fish-outside-tracking-area ]

  ifelse (depth >= the-deep-sea)
    [ fish-head-randomly ]
    [ fish-head-deeper ]

  fd fish-speed
end

to fish-head-randomly ;; fish turtle procedure

; Fish wanders in a random fashion by changing its heading slightly according to the slider variable heading-change-percentage.

  if (random 100 < heading-percentage)
    [ set heading heading + random heading-change-percentage - random heading-change-percentage ]
end

to fish-swim  ;; fish turtle procedure
  ;; turn right if necessary
  if not coastline? (90 * direction) and coastline? (135 * direction) [ rt 90 * direction ]
  ;; turn left if necessary (sometimes more than once)
  while [coastline? 0] [ lt 90 * direction ]
  ;; move forward
  fd fish-speed
end


 ;OUT OF BOUNDS CHECKERS



to-report avoid-coastline? [heading-change]
; Returns true if the turtle the agent needs to aboid the coastline.

  let avoid? true
  ifelse (coastline? 0)
    [ ifelse (random 2 = 0)
        [ set heading heading - heading-change ]
        [ set heading heading + heading-change ]
    ]
    [ ifelse (coastline? heading-change)
        [ set heading heading - heading-change ] ; turn to the left
        [ ifelse (coastline? (- heading-change))
            [ set heading heading + heading-change ] ; turn to the right
            [ set avoid? false ]
        ]
    ]

  report avoid?
end

to-report coastline? [angle]  ;; turtle procedure
  ;; note that angle may be positive or negative.  if angle is
  ;; positive, the turtle looks right.  if angle is negative,
  ;; the turtle looks left.
  let ahead-colour [pcolor] of patch-right-and-ahead angle 1
  report (ahead-colour != sea-colour) and (ahead-colour != deep-sea-colour)
end

to-report outside-tracking-area?   ;; turtle procedure


; Returns true if the turtle is outside of the tracking area.

  report (([pcolor] of patch-here != sea-colour) and (deep-sea-colour = [pcolor] of (patch-ahead 1)))
end


; AUV BEHAVIOURS
to go-AUV-stationary
; AUV behaviour: do nothing

end

to go-AUV-follow-fish
; Robot behaviour: follow the tagged fish.

  let these-fishes fishes in-radius 10
  let this-fish nobody

  ifelse (fish-outside-tracking-area? or AUV-outside-tracking-area?)
    [ AUV-return-to-base ]
    [
      ifelse (outside-tracking-area?)
        [ set AUV-outside-tracking-area? true
          output-print "AUV has gone outside tracking area!" ]
        [
          ifelse (count these-fishes = 0)
            [
              output-print (word "Lost the fish at tick: " ticks)
              fd AUV-speed
            ]
            [
              set this-fish one-of these-fishes
              set heading towards this-fish
              ifelse (distance this-fish > 10)
                [ fd AUV-speed ]
                [
                  output-print (word "Too close to fish, slowing: " ticks)

                  fd AUV-speed / 10
                ] ; too close - slow down
            ]
        ]
    ]
end

to AUV-return-to-base
; Robot behaviour: return the robot to its base.

  ifelse (not AUV-arrived-base-1?)
    [
      set heading (towards patch AUV-base-1-x AUV-base-1-y) + random 10 - random 10
      if (distancexy AUV-base-1-x AUV-base-1-y < 2)
        [ set AUV-arrived-base-1? true ]
    ]
    [
      let next-patch min-one-of neighbors [sea-depth]
      set heading towards next-patch
      if (ycor <= AUV-base-0-y)
        [
          user-message "Reached home base!"
          set AUV-returned-to-home? true
        ]
    ]
  fd AUV-speed
  wait 0.01
end

to-report sea-depth
; Reports the sea depth but sets the depth to a large number if depth = 0 (i.e. not the sea) for sorting purposes
; (as used in above procedure).

  ifelse (depth = 0)
    [ report 99999 ]
    [ report depth ]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
46
1420
817
-1
-1
2.0
1
10
1
1
1
0
1
1
1
-300
300
-190
190
0
0
1
ticks
30.0

BUTTON
9
49
75
82
NIL
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
9
85
72
118
NIL
go\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
216
10
434
60
AUV Simulation (1.0)
20
0.0
1

CHOOSER
13
149
151
194
fish-behaviour
fish-behaviour
"Stationary" "Follow coastline" "Random" "Deeper" "Deeper random"
0

CHOOSER
13
194
151
239
AUV-behaviour
AUV-behaviour
"Stationary" "Follow fish"
1

SLIDER
11
272
183
305
fish-speed
fish-speed
0
10
1.0
0.1
1
NIL
HORIZONTAL

SLIDER
11
305
183
338
AUV-speed
AUV-speed
0
10
1.1
0.1
1
NIL
HORIZONTAL

SLIDER
10
425
182
458
feed-percentage
feed-percentage
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
10
457
182
490
heading-percentage
heading-percentage
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
10
490
181
523
heading-change-percentage
heading-change-percentage
0
100
11.0
1
1
NIL
HORIZONTAL

OUTPUT
1459
92
1795
641
10

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
