;**************************************************************************************
; Project Name:    Neutral Landscape Models Generator
;                  UNIVERSITY OF GREIFSWALD
;
; Author(s):       Romero-Mujalli D.
;
; Written:          7. 7.2021
; Last update:     10. 8.2021
;
; Type of model:   Neutral Landscape Model
;
; Summary:         The purpose of the model is:
;                  to generate artificial landscapes that can be used for understanding
;                  ecological processes in heterogeneous environments / scenarios of
;                  fragmentation.
;                  Currently, the program implements two map generator models:
;                  - Random, and
;                  - Fractal map generators
;
; Acknowledgements: Especial thanks to https://github.com/klaytonkowalski and the
;                 youtube channel of Mathematics of Computer Graphics and Virtual
;                 Environments for their very useful and valuable material, which
;                 helped me in the development of this map generator.
;
;              NOTES / COMMENTS / QUESTIONS:
;
;
;**************************************************************************************
;**************************************************************************************
;                            MIT License
;
;                   Copyright (c) 2019 Daniel Romero Mujalli
;
;   Permission is hereby granted, free of charge, to any person obtaining a copy of
;   this software and associated documentation files (the "Software"), to deal in the
;   Software without restriction, including without limitation the rights to use, copy,
;   modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
;   and to permit persons to whom the Software is furnished to do so, subject to the
;   following conditions:
;
;   The above copyright notice and this permission notice shall be included in all
;   copies or substantial portions of the Software.
;
;   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
;   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
;   PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
;   HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
;   CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
;   OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
;
;**************************************************************************************


; global parameters of the model
globals
[
  HEIGHT-MAP-SIZE  ; Map size, depends on map-scaling-factor
  HABITAT-GOOD     ; suitable habitat color code
  HABITAT-BAD      ; unsuitable habitat color code
  HABITAT-NEUTRAL  ; patch initial color -> white
  RN-MIN           ; random generator, lower bound
  RN-MAX           ; random generator, upper bound
]

; properties of the patches
patches-own
[
  rank             ; value affecting the habitat type of the patch
]


;**************************************************************************************
;        TO SETUP
;**************************************************************************************
; clear the interface, resize world map, and set the initial color of patches
to setup

  ; clear the interface and reset ticks
  clear-all
  reset-ticks

  ; set parameter values
  ; color code:
  ;(see netlogo documentation for more information on permitted values)
  set HABITAT-GOOD 0;52
  set HABITAT-BAD  19.9;48
  set HABITAT-NEUTRAL white

  ; Resize the world-map and its patches
  set HEIGHT-MAP-SIZE (2 ^ map-scaling-factor) + 1
  set-patch-size 1
  resize-world 0 HEIGHT-MAP-SIZE 0 HEIGHT-MAP-SIZE

  ; set lower, upper bound for the random generator
  set RN-MIN -1
  set RN-MAX 1

  ; set initial conditions for the map area
  ask patches [ set pcolor HABITAT-NEUTRAL ]

end

;**************************************************************************************
;        TO GO
;**************************************************************************************
; map generation according to selected method
to go

  ; generate the map according to selected method
   if-else (landscape-type = "random")
  [ set-random-map  ]
  [ set-fractal-map ]

end

;**************************************************************************************
;        TO EXPORT-MAP
;**************************************************************************************
; export the map to file-name.PNG taking advange of the primitive export-view
to export-map

  ; select directory
  set-current-directory user-directory

  let default "map.png"
  ; if file-name is empty or not valid, use default file-name
  if(not empty? file-name and
    is-string? file-name = true and
    substring file-name (length file-name - 3) (length file-name) = "png"
    )
  [ set default file-name ]

  ; export file
  export-view default

end

;**************************************************************************************
;        TO IMPORT-MAP
;**************************************************************************************
; import pcolors from file-name
; if file-name is empty / not valid, print error message
to import-map

  ; select directory
  set-current-directory user-directory

  ; if file-name does not exist pop-up error message
  if-else ( not empty? file-name and file-exists? file-name )
  [
    ; import map
    import-pcolors file-name
  ]
  [; else
    type "unable to find file " type file-name print " in current directory"
  ]


end

;**************************************************************************************
;        TO SET-RANDOM-MAP
;**************************************************************************************
; randomly (Bernoulli distribution) create a proportion p of suitable habitats
to set-random-map

  ;let p 0.5 ; proportion suitable habitats
  let habitats p * (max-pxcor + 1) * (max-pycor + 1)
  ask n-of habitats patches [ set pcolor HABITAT-GOOD ]

end

;**************************************************************************************
;        TO SET-FRACTAL-MAP
;**************************************************************************************
; generate a random map based on the diamond-square algorithm (fractal model). The
; method was developed following the youtube videos by Klayton Kowalski and
; Mathematics of Computer Graphics and Virtual Environments
to set-fractal-map

  ; number of iteration: max_i ~ HEIGHT-MAP-SIZE
  let i 0
  ; h: ROUGHNESS ; the parameter H in With et al. (1997)
  let h 2 ^ (-2 * i * ROUGHNESS)

  ;** INITIALIZATION   ***********
  ; set a random value to each corner of the map
  ask patches with [(pxcor = 0 and pycor = 0) or
                    (pxcor = 0 and pycor = max-pycor) or
                    (pxcor = max-pxcor and pycor = max-pycor) or
                    (pxcor = max-pxcor and pycor = 0)
                   ]
  [
    set rank h * random-uniform RN-MIN RN-MAX
  ]

  ; set initial chunk size: height_map_size - 1
  let chunk-size HEIGHT-MAP-SIZE - 1
  ; set the step (called half) to walk each square / diamond
  let half 0
  ;** END OF INITIALIZATION ******

  ;** UPDATE PATCH RANK **********
  ; based on diamond-square method
  while [chunk-size > 1]
  [
    set i i + 1 ; update iterations
    set h 2 ^ (-2 * i * ROUGHNESS)
    set half chunk-size / 2

    ; square-step
    square-step h half chunk-size
    ; diamond-step
    diamond-step h half chunk-size

    set chunk-size chunk-size / 2
  ]
  ;** END OF UPDATE PATCH RANK ***

  ;** DRAW MAP *******************

  let interval count patches / N-HABITATS
  ; loop control variable
  let k 1
  ; color variable for habitat contagion
  let current-color 131
  ; steps used to walk the rank values and set the corresponding habitat type (color)
  let lower-bound 0 ;min [rank] of patches
  let upper-bound interval ;lower-bound + interval
  while [k <= N-HABITATS ]
  [
    if-else ( k = 1 )
    [
      foreach sublist sort-on [rank] patches lower-bound upper-bound [ the-patch -> ask the-patch [set pcolor HABITAT-GOOD ] ]
      ; update current-color
      set current-color HABITAT-GOOD
    ]
    [ if-else ( k = N-HABITATS )
      [
         foreach sublist sort-on [rank] patches lower-bound upper-bound [ the-patch -> ask the-patch [set pcolor HABITAT-BAD ] ]
         ;set current-color HABITAT-BAD ; drop error due to agentset with only one element :S
      ]
      [;else
        foreach sublist sort-on [rank] patches lower-bound upper-bound [ the-patch -> ask the-patch [set pcolor HABITAT-GOOD + k * 1] ] ; plus 10 typically change color name
        set current-color HABITAT-GOOD + k * 1
      ]
    ]

    ; simulate spatial habitat contagion to smooth the landscape
    ; patches surounded by suitable neighbors turn suitable as well
    ask patches with
    [count neighbors with [pcolor = current-color] >= habitat-contagion]
    [ set pcolor 131 ]
    ; turn black all pink patches
    ask patches with [pcolor = 131] [ set pcolor current-color ]

    ; update walking steps and loop-control variable before repeatin the loop
    set lower-bound upper-bound
    set upper-bound upper-bound + interval
    set k k + 1
  ]

  ; habitat contagion to smooth the landscape of the HABITAT-BAD
  ask patches with
  [count neighbors with [pcolor = HABITAT-BAD] >= habitat-contagion]
  [ set pcolor 131 ]
  ; turn black all pink patches
  ask patches with [pcolor = 131] [ set pcolor HABITAT-BAD ]
  ;** END OF DRAW MAP ************
end

;**************************************************************************************
;        TO SQUARE-STEP
;**************************************************************************************
; perform the square step of the diamond-square algorithm
; arguments to the function:
; h: range of the random generator. Already accounts for the roughness
; half: current step value used to walk each square
; chunk-size: current chunk-size value (a chunk is the size of a square)
to square-step [ h half chunk-size ]

  ; initialization at position (1,1)
  let x0 1
  let y0 1
  ;print ("in")
  while [ x0 < max-pxcor - 1 ]
  [
    ; set the rank of the middle point patch (of the current square)
    ask patch (x0 + half) (y0 + half)
    [
      set rank (h * random-uniform RN-MIN RN-MAX) +
     ([rank] of patch (x0) (y0) +
      [rank] of patch (x0) (y0 + chunk-size) +
      [rank] of patch (x0 + chunk-size) (y0 + chunk-size) +
      [rank] of patch (x0 + chunk-size) (y0)) / 4
    ]
    ; move to next square
    set y0 y0 + chunk-size
    if( y0 > max-pycor - 1 )
    [
      set y0 0
      set x0 x0 + chunk-size
    ]
    ;type "chunksize" print chunk-size
    ;type "y:" print y0
    ;type "x:" print x0
  ]
  ;print("out")

end

;**************************************************************************************
;        TO DIAMOND-STEP
;**************************************************************************************
; perform the diamond step of the diamond-square algorithm
; arguments to the function:
; h: range of the random generator. Already accounts for the roughness
; half: current step value used to walk each square
; chunk-size: current chunk-size value (a chunk is the size of a square)
to diamond-step [ h half chunk-size ]

  ; initialization at position (1, half step)
  let x0 1
  let y0 (x0 + half) mod chunk-size
  ; result and n-count are used such that the mean rank of neighboring patches
  ; does not include patches outside map range (i.e., undefined patches)
  let result 0
  let n-count 0

  ;print("in")
  while [ x0 < max-pxcor ]
  [
    if (y0 = 0)[ set y0 chunk-size ]

    ; set the rank value of the middle point of the diamond
    ; omit patches outside map range, and
    ; update the sum result (and count, for average)
    if(x0 - half > 0)
    [
      set result result + [rank] of patch (x0 - half) (y0)
      set n-count n-count + 1
    ]
    if(y0 - half > 0)
    [
      set result result + [rank] of patch (x0) (y0 - half)
      set n-count n-count + 1
    ]
    if(y0 + half <= HEIGHT-MAP-SIZE)
    [
      set result result + [rank] of patch (x0) (y0 + half)
      set n-count n-count + 1
    ]
    if(x0 + half <= HEIGHT-MAP-SIZE)
    [
      set result result + [rank] of patch (x0 + half) (y0)
      set n-count n-count + 1
    ]

    ask patch (x0) (y0)
    [
      set rank (h * random-uniform RN-MIN RN-MAX) + (result / n-count)
    ]

    ; find the next diamond
    set y0 y0 + chunk-size
    if( y0 > max-pycor )
    [
      set y0 (x0 + half) mod chunk-size
      set x0 x0 + half
    ]

    ; reset result and n-count
    set result 0
    set n-count 0
  ]

end

;**************************************************************************************
;        TO-REPORT RANDOM-UNIFORM
;**************************************************************************************
; custom random generator in range (min-value, max-value)
; random generator according to uniform distribution
to-report random-uniform [min-value max-value]

  report min-value + random (max-value + 1 - min-value)

end

;**************************************************************************************
;        CHANGE LOG
;**************************************************************************************
;
; v1_2
; implementation of N-HABITATS and export / import functions
; Random generator range defined by constant (RN-MIN, RN-MAX)
@#$#@#$#@
GRAPHICS-WINDOW
358
10
880
533
-1
-1
1.0
1
10
1
1
1
0
1
1
1
0
513
0
513
0
0
1
ticks
30.0

BUTTON
5
57
93
90
clear-all
Setup
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
96
57
230
90
generate-map
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
204
271
356
304
ROUGHNESS
ROUGHNESS
0
1
0.7
0.1
1
NIL
HORIZONTAL

SLIDER
204
307
356
340
map-scaling-factor
map-scaling-factor
1
10
9.0
1
1
NIL
HORIZONTAL

CHOOSER
2
180
356
225
landscape-type
landscape-type
"random" "fractal"
1

SLIDER
2
271
155
304
p
p
0
1
0.5
0.01
1
NIL
HORIZONTAL

TEXTBOX
45
251
111
269
RANDOM
12
0.0
1

TEXTBOX
248
250
336
268
FRACTAL
12
0.0
1

TEXTBOX
18
13
332
35
NEUTRAL LANDSCAPE MODELS GENERATOR
14
54.0
1

SLIDER
204
343
356
376
habitat-contagion
habitat-contagion
1
8
7.0
1
1
NIL
HORIZONTAL

SLIDER
204
378
356
411
N-HABITATS
N-HABITATS
2
5
3.0
1
1
NIL
HORIZONTAL

BUTTON
96
91
230
124
export-map
export-map
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
232
57
357
124
file-name
map.png
1
0
String

BUTTON
96
125
230
158
import-map
import-map
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

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
NetLogo 6.2.0
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
