!include integer_ids.i

[GlobalParams]
  use_displaced_mesh = true
[]
[Mesh]
  displacements = 'disp_x disp_y'
[]
[Variables]
  [disp_x]
  []
  [disp_y]
  []
[]
[Kernels]
  [x_storage]
    type = TimeDerivative
    variable = disp_x
  []
  [y_storage]
    type = TimeDerivative
    variable = disp_y
  []
[]
