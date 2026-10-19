# Generated case: nh; polymer NH; 242 particles.
[Mesh]
    [read_mesh]
        type = FileMeshGenerator
        file = 'microstructures_20261003_210951_b0e48458_layout_01_separate.msh'
    []
[]

[GlobalParams]
        displacements = 'disp_x disp_y'
        use_displaced_mesh = true
        exponential_stretch_approximation = true
        use_artificial_viscosity = false

[]

[AuxVariables]
  [h_min]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[AuxKernels]
  [compute_h_min]
    type = ElementLengthAux
    variable = h_min
    method = min
    execute_on = INITIAL
  []
[]

[Postprocessors]
  [global_hmin]
    type = ElementExtremeValue
    variable = h_min
    value_type = min
    execute_on = INITIAL
  []
[]

[Materials]
  [minimum_mesh_size]
    type = ParsedMaterial
    property_name = h_min
    postprocessor_names = 'global_hmin'
    expression = 'global_hmin'
  []
[]

[Variables]
    [disp_x]
    []

    [disp_y]
    []

    [c]
        initial_condition = 0.0
    []

    [temperature]
        initial_condition = 300.0
    []
[]

#materials
#we set materials for fracture first

[Materials]
    [constants]
        type = ADGenericConstantMaterial
        prop_names = 'density bulk poisson gc k_r sigma_r eta l'
        prop_values = '1.820e-3 20e3 0.34 0.04 1e-5 0.8 500 3'
        block = 'particle_1 particle_2 particle_3 particle_4 particle_5 particle_6 particle_7 particle_8 particle_9 particle_10 particle_11 particle_12 particle_13 particle_14 particle_15 particle_16 particle_17 particle_18 particle_19 particle_20 particle_21 particle_22 particle_23 particle_24 particle_25 particle_26 particle_27 particle_28 particle_29 particle_30 particle_31 particle_32 particle_33 particle_34 particle_35 particle_36 particle_37 particle_38 particle_39 particle_40 particle_41 particle_42 particle_43 particle_44 particle_45 particle_46 particle_47 particle_48 particle_49 particle_50 particle_51 particle_52 particle_53 particle_54 particle_55 particle_56 particle_57 particle_58 particle_59 particle_60 particle_61 particle_62 particle_63 particle_64 particle_65 particle_66 particle_67 particle_68 particle_69 particle_70 particle_71 particle_72 particle_73 particle_74 particle_75 particle_76 particle_77 particle_78 particle_79 particle_80 particle_81 particle_82 particle_83 particle_84 particle_85 particle_86 particle_87 particle_88 particle_89 particle_90 particle_91 particle_92 particle_93 particle_94 particle_95 particle_96 particle_97 particle_98 particle_99 particle_100 particle_101 particle_102 particle_103 particle_104 particle_105 particle_106 particle_107 particle_108 particle_109 particle_110 particle_111 particle_112 particle_113 particle_114 particle_115 particle_116 particle_117 particle_118 particle_119 particle_120 particle_121 particle_122 particle_123 particle_124 particle_125 particle_126 particle_127 particle_128 particle_129 particle_130 particle_131 particle_132 particle_133 particle_134 particle_135 particle_136 particle_137 particle_138 particle_139 particle_140 particle_141 particle_142 particle_143 particle_144 particle_145 particle_146 particle_147 particle_148 particle_149 particle_150 particle_151 particle_152 particle_153 particle_154 particle_155 particle_156 particle_157 particle_158 particle_159 particle_160 particle_161 particle_162 particle_163 particle_164 particle_165 particle_166 particle_167 particle_168 particle_169 particle_170 particle_171 particle_172 particle_173 particle_174 particle_175 particle_176 particle_177 particle_178 particle_179 particle_180 particle_181 particle_182 particle_183 particle_184 particle_185 particle_186 particle_187 particle_188 particle_189 particle_190 particle_191 particle_192 particle_193 particle_194 particle_195 particle_196 particle_197 particle_198 particle_199 particle_200 particle_201 particle_202 particle_203 particle_204 particle_205 particle_206 particle_207 particle_208 particle_209 particle_210 particle_211 particle_212 particle_213 particle_214 particle_215 particle_216 particle_217 particle_218 particle_219 particle_220 particle_221 particle_222 particle_223 particle_224 particle_225 particle_226 particle_227 particle_228 particle_229 particle_230 particle_231 particle_232 particle_233 particle_234 particle_235 particle_236 particle_237 particle_238 particle_239 particle_240 particle_241 particle_242'
    []
    [constants_matrix]
        type = ADGenericConstantMaterial
        prop_names = 'density bulk poisson gc k_r sigma_r eta l'
        prop_values = '1.02e-3 3e3 0.35 0.4 1e-5 0.8 500 3'
        block = 'matrix'
    []

    #define degradation properties
    [De]
        type = ADDerivativeParsedMaterial
        material_property_names = 'k_r'
        coupled_variables = 'c'
        expression = '(1 - k_r) * (1 - c)^2 + k_r'
        derivative_order = 2
        outputs = exodus
        property_name = 'De'
    []
    [Dp]
        type = ADDerivativeParsedMaterial
        material_property_names = 'sigma_r'
        coupled_variables = 'c'
        expression = '(1 - sigma_r) * (1 - c)^2 + sigma_r'
        derivative_order = 2
        outputs = exodus
        property_name = 'Dp'
    []

    #compute incremental deformation gradient
    [incremental]
        type = ADComputeFiniteStrain
        displacements = 'disp_x disp_y'
        decomposition_method = EigenSolution
    []

    #stress calculation
    [elasto_plastic_particles]
        type = ADElastoPlastic
        flow_stress_material = 'flow_stress'
        bulk_modulus_name = 'bulk'
        poisson_ratio_name = 'poisson'
        elastic_degradation_name = 'De'
        plastic_degradation_name = 'Dp'
        temperature = temperature
        outputs = exodus
        block = 'particle_1 particle_2 particle_3 particle_4 particle_5 particle_6 particle_7 particle_8 particle_9 particle_10 particle_11 particle_12 particle_13 particle_14 particle_15 particle_16 particle_17 particle_18 particle_19 particle_20 particle_21 particle_22 particle_23 particle_24 particle_25 particle_26 particle_27 particle_28 particle_29 particle_30 particle_31 particle_32 particle_33 particle_34 particle_35 particle_36 particle_37 particle_38 particle_39 particle_40 particle_41 particle_42 particle_43 particle_44 particle_45 particle_46 particle_47 particle_48 particle_49 particle_50 particle_51 particle_52 particle_53 particle_54 particle_55 particle_56 particle_57 particle_58 particle_59 particle_60 particle_61 particle_62 particle_63 particle_64 particle_65 particle_66 particle_67 particle_68 particle_69 particle_70 particle_71 particle_72 particle_73 particle_74 particle_75 particle_76 particle_77 particle_78 particle_79 particle_80 particle_81 particle_82 particle_83 particle_84 particle_85 particle_86 particle_87 particle_88 particle_89 particle_90 particle_91 particle_92 particle_93 particle_94 particle_95 particle_96 particle_97 particle_98 particle_99 particle_100 particle_101 particle_102 particle_103 particle_104 particle_105 particle_106 particle_107 particle_108 particle_109 particle_110 particle_111 particle_112 particle_113 particle_114 particle_115 particle_116 particle_117 particle_118 particle_119 particle_120 particle_121 particle_122 particle_123 particle_124 particle_125 particle_126 particle_127 particle_128 particle_129 particle_130 particle_131 particle_132 particle_133 particle_134 particle_135 particle_136 particle_137 particle_138 particle_139 particle_140 particle_141 particle_142 particle_143 particle_144 particle_145 particle_146 particle_147 particle_148 particle_149 particle_150 particle_151 particle_152 particle_153 particle_154 particle_155 particle_156 particle_157 particle_158 particle_159 particle_160 particle_161 particle_162 particle_163 particle_164 particle_165 particle_166 particle_167 particle_168 particle_169 particle_170 particle_171 particle_172 particle_173 particle_174 particle_175 particle_176 particle_177 particle_178 particle_179 particle_180 particle_181 particle_182 particle_183 particle_184 particle_185 particle_186 particle_187 particle_188 particle_189 particle_190 particle_191 particle_192 particle_193 particle_194 particle_195 particle_196 particle_197 particle_198 particle_199 particle_200 particle_201 particle_202 particle_203 particle_204 particle_205 particle_206 particle_207 particle_208 particle_209 particle_210 particle_211 particle_212 particle_213 particle_214 particle_215 particle_216 particle_217 particle_218 particle_219 particle_220 particle_221 particle_222 particle_223 particle_224 particle_225 particle_226 particle_227 particle_228 particle_229 particle_230 particle_231 particle_232 particle_233 particle_234 particle_235 particle_236 particle_237 particle_238 particle_239 particle_240 particle_241 particle_242'
        constitutive_model = NH
    []
    [elasto_plastic_polymer]
        type = ADElastoPlastic
        flow_stress_material = 'flow_stress'
        bulk_modulus_name = 'bulk'
        poisson_ratio_name = 'poisson'
        elastic_degradation_name = 'De'
        plastic_degradation_name = 'Dp'
        temperature = temperature
        outputs = exodus
        block = 'matrix'
        constitutive_model = NH
    []


    #yield stress material
    [yield_properties]
        type = ADGenericConstantMaterial
        prop_names = 'A B n'
        prop_values = '80 30 3'
        block = 'matrix'
    []
    [yield_properties_particles]
        type = ADGenericConstantMaterial
        prop_names = 'A B n'
        prop_values = '200 200 0.1'
        block = 'particle_1 particle_2 particle_3 particle_4 particle_5 particle_6 particle_7 particle_8 particle_9 particle_10 particle_11 particle_12 particle_13 particle_14 particle_15 particle_16 particle_17 particle_18 particle_19 particle_20 particle_21 particle_22 particle_23 particle_24 particle_25 particle_26 particle_27 particle_28 particle_29 particle_30 particle_31 particle_32 particle_33 particle_34 particle_35 particle_36 particle_37 particle_38 particle_39 particle_40 particle_41 particle_42 particle_43 particle_44 particle_45 particle_46 particle_47 particle_48 particle_49 particle_50 particle_51 particle_52 particle_53 particle_54 particle_55 particle_56 particle_57 particle_58 particle_59 particle_60 particle_61 particle_62 particle_63 particle_64 particle_65 particle_66 particle_67 particle_68 particle_69 particle_70 particle_71 particle_72 particle_73 particle_74 particle_75 particle_76 particle_77 particle_78 particle_79 particle_80 particle_81 particle_82 particle_83 particle_84 particle_85 particle_86 particle_87 particle_88 particle_89 particle_90 particle_91 particle_92 particle_93 particle_94 particle_95 particle_96 particle_97 particle_98 particle_99 particle_100 particle_101 particle_102 particle_103 particle_104 particle_105 particle_106 particle_107 particle_108 particle_109 particle_110 particle_111 particle_112 particle_113 particle_114 particle_115 particle_116 particle_117 particle_118 particle_119 particle_120 particle_121 particle_122 particle_123 particle_124 particle_125 particle_126 particle_127 particle_128 particle_129 particle_130 particle_131 particle_132 particle_133 particle_134 particle_135 particle_136 particle_137 particle_138 particle_139 particle_140 particle_141 particle_142 particle_143 particle_144 particle_145 particle_146 particle_147 particle_148 particle_149 particle_150 particle_151 particle_152 particle_153 particle_154 particle_155 particle_156 particle_157 particle_158 particle_159 particle_160 particle_161 particle_162 particle_163 particle_164 particle_165 particle_166 particle_167 particle_168 particle_169 particle_170 particle_171 particle_172 particle_173 particle_174 particle_175 particle_176 particle_177 particle_178 particle_179 particle_180 particle_181 particle_182 particle_183 particle_184 particle_185 particle_186 particle_187 particle_188 particle_189 particle_190 particle_191 particle_192 particle_193 particle_194 particle_195 particle_196 particle_197 particle_198 particle_199 particle_200 particle_201 particle_202 particle_203 particle_204 particle_205 particle_206 particle_207 particle_208 particle_209 particle_210 particle_211 particle_212 particle_213 particle_214 particle_215 particle_216 particle_217 particle_218 particle_219 particle_220 particle_221 particle_222 particle_223 particle_224 particle_225 particle_226 particle_227 particle_228 particle_229 particle_230 particle_231 particle_232 particle_233 particle_234 particle_235 particle_236 particle_237 particle_238 particle_239 particle_240 particle_241 particle_242'
    []
    [flow_stress]
        type = ADDerivativeParsedMaterial
        material_property_names = 'ep A B n'
        expression = 'A + B * ep ^ n'
        additional_derivative_symbols = 'ep'
        derivative_order = 2
        property_name = 'flow_stress'
        compute = false
    []

    #materials for phase field: 
    #we need to define the total energy
    [plastic_energy]
        type = ADDerivativeParsedMaterial
        material_property_names = 'flow_stress ep A B n'
        expression = 'A*ep + B/(n+1)*ep^(n+1)'
        property_name = 'Wp'
    []
    
    [total_energy]
        type = ADDerivativeParsedMaterial
        coupled_variables = 'c'
        material_property_names = 'De:=De(c) Dp:=Dp(c) Hist Wp gc l'
        expression = 'De * Hist + Dp * Wp + (gc * c * c) / (2 * l)'
        property_name = 'bulk_energy'
        outputs = exodus
    []

    #mobility and kappa
    [L]
        type = ADParsedMaterial
        material_property_names = 'gc eta'
        expression = '1 / (gc * eta)'
        property_name = 'L'
    []
    [kappa]
        type = ADParsedMaterial
        material_property_names = 'gc l'
        expression = 'gc * l'
        property_name = 'kappa'
    []
[]

[Kernels]
    #temperature
    [T_dot]
        type = ADTimeDerivative
        variable = temperature
    []

    #stress divergence: quasistatic case
    [div_x]
        type = ADDynamicStressDivergenceTensors
        component = 0
        displacements = 'disp_x disp_y'
        variable = 'disp_x'
    []
    [div_y]
        type = ADDynamicStressDivergenceTensors
        component = 1
        displacements = 'disp_x disp_y'
        variable = 'disp_y'
    []

    #fracture stuff
    [c_dot]
        type = ADTimeDerivative
        variable = c
    []
    #allen cahn bulk
    [bulk_variation]
        type = ADAllenCahn
        f_name = 'bulk_energy'
        variable = c
        mob_name = 'L'
    []
    [interface_variation]
        type = ADACInterface
        variable = c
        kappa_name = 'kappa'
        mob_name = 'L'
        variable_L = False
    []
[]

[Functions]
    [opening_right]
        type = ParsedFunction
        expression = '5e-3*t'
    []
    [opening_left]
        type = ParsedFunction
        expression = '-5e-3*t'
    []
[]

[Postprocessors]
        [reaction]
                type = ADSidesetReaction
                direction = '1 0 0'
                stress_tensor = pk1
                boundary = right
        []
[]

[BCs]
    [right_opening]
        type = FunctionDirichletBC
        variable = disp_x
        boundary = right
        function = opening_right
    []

    #[left_opening]
    #    type = FunctionDirichletBC
    #    variable = disp_x
    #    boundary = left
    #    function = opening_left
    #[]

    #keep shear displacement zero
    [right_vert_fix]
        type = DirichletBC
        variable = disp_x
        boundary = 'left'
        value = 0.0
    []
        [top_bottom]
                type = DirichletBC
                variable = 'disp_y'
                boundary = 'top bottom'
                value = 0.0
        []
[]

#solver
[Executioner]
    type = Transient
    [./TimeStepper]
        type = FunctionDT
        function = timestep
        min_dt = 1e-7
        growth_factor = 1.25
        cutback_factor_at_failure = 0.25
    [../]
    nl_rel_tol = 1e-7
    nl_abs_tol = 1e-7
    l_tol = 1e-6
    l_max_its = 200
    solve_type = Newton
    petsc_options_iname = '-ksp_type -pc_type -pc_factor_mat_solver_type'
    petsc_options_value = 'preonly   lu       mumps'
    petsc_options = '-snes_converged_reason -ksp_converged_reason -snes_linesearch_monitor'
    automatic_scaling = true
    line_search = 'bt'
[]

[Preconditioning]
    [coup]
        type = SMP
        full = true
    []
[]

[Functions]
    [./timestep]
        type = ParsedFunction
        expression = '50'
    [../]
[]

[Outputs]
    exodus = true
    csv = true
    time_step_interval = 10
[]
