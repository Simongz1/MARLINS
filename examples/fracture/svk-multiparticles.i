# Generated case: svk_unrotated; polymer NH; 242 particles.
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
        constitutive_model = SVK
        elasticity_tensor_name = elasticity_tensor
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
    # Alpha polymorph stiffness in MPa; material axis 1 is the c-axis.
    # symmetric9: C11 C12 C13 C22 C23 C33 C44 C55 C66.
    # Euler angles: MOOSE Z-X-Z convention, degrees.
    [elasticity_particle_1]
        type = ADComputeElasticityTensor
        block = particle_1
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_2]
        type = ADComputeElasticityTensor
        block = particle_2
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_3]
        type = ADComputeElasticityTensor
        block = particle_3
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_4]
        type = ADComputeElasticityTensor
        block = particle_4
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_5]
        type = ADComputeElasticityTensor
        block = particle_5
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_6]
        type = ADComputeElasticityTensor
        block = particle_6
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_7]
        type = ADComputeElasticityTensor
        block = particle_7
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_8]
        type = ADComputeElasticityTensor
        block = particle_8
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_9]
        type = ADComputeElasticityTensor
        block = particle_9
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_10]
        type = ADComputeElasticityTensor
        block = particle_10
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_11]
        type = ADComputeElasticityTensor
        block = particle_11
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_12]
        type = ADComputeElasticityTensor
        block = particle_12
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_13]
        type = ADComputeElasticityTensor
        block = particle_13
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_14]
        type = ADComputeElasticityTensor
        block = particle_14
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_15]
        type = ADComputeElasticityTensor
        block = particle_15
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_16]
        type = ADComputeElasticityTensor
        block = particle_16
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_17]
        type = ADComputeElasticityTensor
        block = particle_17
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_18]
        type = ADComputeElasticityTensor
        block = particle_18
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_19]
        type = ADComputeElasticityTensor
        block = particle_19
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_20]
        type = ADComputeElasticityTensor
        block = particle_20
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_21]
        type = ADComputeElasticityTensor
        block = particle_21
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_22]
        type = ADComputeElasticityTensor
        block = particle_22
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_23]
        type = ADComputeElasticityTensor
        block = particle_23
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_24]
        type = ADComputeElasticityTensor
        block = particle_24
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_25]
        type = ADComputeElasticityTensor
        block = particle_25
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_26]
        type = ADComputeElasticityTensor
        block = particle_26
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_27]
        type = ADComputeElasticityTensor
        block = particle_27
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_28]
        type = ADComputeElasticityTensor
        block = particle_28
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_29]
        type = ADComputeElasticityTensor
        block = particle_29
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_30]
        type = ADComputeElasticityTensor
        block = particle_30
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_31]
        type = ADComputeElasticityTensor
        block = particle_31
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_32]
        type = ADComputeElasticityTensor
        block = particle_32
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_33]
        type = ADComputeElasticityTensor
        block = particle_33
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_34]
        type = ADComputeElasticityTensor
        block = particle_34
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_35]
        type = ADComputeElasticityTensor
        block = particle_35
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_36]
        type = ADComputeElasticityTensor
        block = particle_36
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_37]
        type = ADComputeElasticityTensor
        block = particle_37
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_38]
        type = ADComputeElasticityTensor
        block = particle_38
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_39]
        type = ADComputeElasticityTensor
        block = particle_39
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_40]
        type = ADComputeElasticityTensor
        block = particle_40
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_41]
        type = ADComputeElasticityTensor
        block = particle_41
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_42]
        type = ADComputeElasticityTensor
        block = particle_42
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_43]
        type = ADComputeElasticityTensor
        block = particle_43
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_44]
        type = ADComputeElasticityTensor
        block = particle_44
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_45]
        type = ADComputeElasticityTensor
        block = particle_45
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_46]
        type = ADComputeElasticityTensor
        block = particle_46
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_47]
        type = ADComputeElasticityTensor
        block = particle_47
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_48]
        type = ADComputeElasticityTensor
        block = particle_48
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_49]
        type = ADComputeElasticityTensor
        block = particle_49
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_50]
        type = ADComputeElasticityTensor
        block = particle_50
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_51]
        type = ADComputeElasticityTensor
        block = particle_51
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_52]
        type = ADComputeElasticityTensor
        block = particle_52
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_53]
        type = ADComputeElasticityTensor
        block = particle_53
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_54]
        type = ADComputeElasticityTensor
        block = particle_54
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_55]
        type = ADComputeElasticityTensor
        block = particle_55
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_56]
        type = ADComputeElasticityTensor
        block = particle_56
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_57]
        type = ADComputeElasticityTensor
        block = particle_57
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_58]
        type = ADComputeElasticityTensor
        block = particle_58
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_59]
        type = ADComputeElasticityTensor
        block = particle_59
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_60]
        type = ADComputeElasticityTensor
        block = particle_60
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_61]
        type = ADComputeElasticityTensor
        block = particle_61
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_62]
        type = ADComputeElasticityTensor
        block = particle_62
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_63]
        type = ADComputeElasticityTensor
        block = particle_63
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_64]
        type = ADComputeElasticityTensor
        block = particle_64
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_65]
        type = ADComputeElasticityTensor
        block = particle_65
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_66]
        type = ADComputeElasticityTensor
        block = particle_66
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_67]
        type = ADComputeElasticityTensor
        block = particle_67
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_68]
        type = ADComputeElasticityTensor
        block = particle_68
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_69]
        type = ADComputeElasticityTensor
        block = particle_69
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_70]
        type = ADComputeElasticityTensor
        block = particle_70
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_71]
        type = ADComputeElasticityTensor
        block = particle_71
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_72]
        type = ADComputeElasticityTensor
        block = particle_72
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_73]
        type = ADComputeElasticityTensor
        block = particle_73
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_74]
        type = ADComputeElasticityTensor
        block = particle_74
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_75]
        type = ADComputeElasticityTensor
        block = particle_75
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_76]
        type = ADComputeElasticityTensor
        block = particle_76
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_77]
        type = ADComputeElasticityTensor
        block = particle_77
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_78]
        type = ADComputeElasticityTensor
        block = particle_78
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_79]
        type = ADComputeElasticityTensor
        block = particle_79
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_80]
        type = ADComputeElasticityTensor
        block = particle_80
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_81]
        type = ADComputeElasticityTensor
        block = particle_81
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_82]
        type = ADComputeElasticityTensor
        block = particle_82
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_83]
        type = ADComputeElasticityTensor
        block = particle_83
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_84]
        type = ADComputeElasticityTensor
        block = particle_84
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_85]
        type = ADComputeElasticityTensor
        block = particle_85
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_86]
        type = ADComputeElasticityTensor
        block = particle_86
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_87]
        type = ADComputeElasticityTensor
        block = particle_87
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_88]
        type = ADComputeElasticityTensor
        block = particle_88
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_89]
        type = ADComputeElasticityTensor
        block = particle_89
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_90]
        type = ADComputeElasticityTensor
        block = particle_90
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_91]
        type = ADComputeElasticityTensor
        block = particle_91
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_92]
        type = ADComputeElasticityTensor
        block = particle_92
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_93]
        type = ADComputeElasticityTensor
        block = particle_93
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_94]
        type = ADComputeElasticityTensor
        block = particle_94
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_95]
        type = ADComputeElasticityTensor
        block = particle_95
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_96]
        type = ADComputeElasticityTensor
        block = particle_96
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_97]
        type = ADComputeElasticityTensor
        block = particle_97
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_98]
        type = ADComputeElasticityTensor
        block = particle_98
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_99]
        type = ADComputeElasticityTensor
        block = particle_99
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_100]
        type = ADComputeElasticityTensor
        block = particle_100
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_101]
        type = ADComputeElasticityTensor
        block = particle_101
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_102]
        type = ADComputeElasticityTensor
        block = particle_102
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_103]
        type = ADComputeElasticityTensor
        block = particle_103
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_104]
        type = ADComputeElasticityTensor
        block = particle_104
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_105]
        type = ADComputeElasticityTensor
        block = particle_105
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_106]
        type = ADComputeElasticityTensor
        block = particle_106
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_107]
        type = ADComputeElasticityTensor
        block = particle_107
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_108]
        type = ADComputeElasticityTensor
        block = particle_108
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_109]
        type = ADComputeElasticityTensor
        block = particle_109
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_110]
        type = ADComputeElasticityTensor
        block = particle_110
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_111]
        type = ADComputeElasticityTensor
        block = particle_111
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_112]
        type = ADComputeElasticityTensor
        block = particle_112
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_113]
        type = ADComputeElasticityTensor
        block = particle_113
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_114]
        type = ADComputeElasticityTensor
        block = particle_114
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_115]
        type = ADComputeElasticityTensor
        block = particle_115
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_116]
        type = ADComputeElasticityTensor
        block = particle_116
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_117]
        type = ADComputeElasticityTensor
        block = particle_117
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_118]
        type = ADComputeElasticityTensor
        block = particle_118
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_119]
        type = ADComputeElasticityTensor
        block = particle_119
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_120]
        type = ADComputeElasticityTensor
        block = particle_120
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_121]
        type = ADComputeElasticityTensor
        block = particle_121
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_122]
        type = ADComputeElasticityTensor
        block = particle_122
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_123]
        type = ADComputeElasticityTensor
        block = particle_123
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_124]
        type = ADComputeElasticityTensor
        block = particle_124
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_125]
        type = ADComputeElasticityTensor
        block = particle_125
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_126]
        type = ADComputeElasticityTensor
        block = particle_126
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_127]
        type = ADComputeElasticityTensor
        block = particle_127
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_128]
        type = ADComputeElasticityTensor
        block = particle_128
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_129]
        type = ADComputeElasticityTensor
        block = particle_129
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_130]
        type = ADComputeElasticityTensor
        block = particle_130
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_131]
        type = ADComputeElasticityTensor
        block = particle_131
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_132]
        type = ADComputeElasticityTensor
        block = particle_132
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_133]
        type = ADComputeElasticityTensor
        block = particle_133
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_134]
        type = ADComputeElasticityTensor
        block = particle_134
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_135]
        type = ADComputeElasticityTensor
        block = particle_135
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_136]
        type = ADComputeElasticityTensor
        block = particle_136
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_137]
        type = ADComputeElasticityTensor
        block = particle_137
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_138]
        type = ADComputeElasticityTensor
        block = particle_138
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_139]
        type = ADComputeElasticityTensor
        block = particle_139
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_140]
        type = ADComputeElasticityTensor
        block = particle_140
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_141]
        type = ADComputeElasticityTensor
        block = particle_141
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_142]
        type = ADComputeElasticityTensor
        block = particle_142
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_143]
        type = ADComputeElasticityTensor
        block = particle_143
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_144]
        type = ADComputeElasticityTensor
        block = particle_144
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_145]
        type = ADComputeElasticityTensor
        block = particle_145
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_146]
        type = ADComputeElasticityTensor
        block = particle_146
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_147]
        type = ADComputeElasticityTensor
        block = particle_147
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_148]
        type = ADComputeElasticityTensor
        block = particle_148
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_149]
        type = ADComputeElasticityTensor
        block = particle_149
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_150]
        type = ADComputeElasticityTensor
        block = particle_150
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_151]
        type = ADComputeElasticityTensor
        block = particle_151
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_152]
        type = ADComputeElasticityTensor
        block = particle_152
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_153]
        type = ADComputeElasticityTensor
        block = particle_153
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_154]
        type = ADComputeElasticityTensor
        block = particle_154
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_155]
        type = ADComputeElasticityTensor
        block = particle_155
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_156]
        type = ADComputeElasticityTensor
        block = particle_156
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_157]
        type = ADComputeElasticityTensor
        block = particle_157
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_158]
        type = ADComputeElasticityTensor
        block = particle_158
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_159]
        type = ADComputeElasticityTensor
        block = particle_159
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_160]
        type = ADComputeElasticityTensor
        block = particle_160
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_161]
        type = ADComputeElasticityTensor
        block = particle_161
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_162]
        type = ADComputeElasticityTensor
        block = particle_162
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_163]
        type = ADComputeElasticityTensor
        block = particle_163
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_164]
        type = ADComputeElasticityTensor
        block = particle_164
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_165]
        type = ADComputeElasticityTensor
        block = particle_165
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_166]
        type = ADComputeElasticityTensor
        block = particle_166
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_167]
        type = ADComputeElasticityTensor
        block = particle_167
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_168]
        type = ADComputeElasticityTensor
        block = particle_168
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_169]
        type = ADComputeElasticityTensor
        block = particle_169
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_170]
        type = ADComputeElasticityTensor
        block = particle_170
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_171]
        type = ADComputeElasticityTensor
        block = particle_171
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_172]
        type = ADComputeElasticityTensor
        block = particle_172
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_173]
        type = ADComputeElasticityTensor
        block = particle_173
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_174]
        type = ADComputeElasticityTensor
        block = particle_174
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_175]
        type = ADComputeElasticityTensor
        block = particle_175
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_176]
        type = ADComputeElasticityTensor
        block = particle_176
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_177]
        type = ADComputeElasticityTensor
        block = particle_177
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_178]
        type = ADComputeElasticityTensor
        block = particle_178
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_179]
        type = ADComputeElasticityTensor
        block = particle_179
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_180]
        type = ADComputeElasticityTensor
        block = particle_180
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_181]
        type = ADComputeElasticityTensor
        block = particle_181
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_182]
        type = ADComputeElasticityTensor
        block = particle_182
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_183]
        type = ADComputeElasticityTensor
        block = particle_183
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_184]
        type = ADComputeElasticityTensor
        block = particle_184
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_185]
        type = ADComputeElasticityTensor
        block = particle_185
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_186]
        type = ADComputeElasticityTensor
        block = particle_186
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_187]
        type = ADComputeElasticityTensor
        block = particle_187
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_188]
        type = ADComputeElasticityTensor
        block = particle_188
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_189]
        type = ADComputeElasticityTensor
        block = particle_189
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_190]
        type = ADComputeElasticityTensor
        block = particle_190
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_191]
        type = ADComputeElasticityTensor
        block = particle_191
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_192]
        type = ADComputeElasticityTensor
        block = particle_192
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_193]
        type = ADComputeElasticityTensor
        block = particle_193
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_194]
        type = ADComputeElasticityTensor
        block = particle_194
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_195]
        type = ADComputeElasticityTensor
        block = particle_195
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_196]
        type = ADComputeElasticityTensor
        block = particle_196
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_197]
        type = ADComputeElasticityTensor
        block = particle_197
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_198]
        type = ADComputeElasticityTensor
        block = particle_198
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_199]
        type = ADComputeElasticityTensor
        block = particle_199
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_200]
        type = ADComputeElasticityTensor
        block = particle_200
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_201]
        type = ADComputeElasticityTensor
        block = particle_201
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_202]
        type = ADComputeElasticityTensor
        block = particle_202
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_203]
        type = ADComputeElasticityTensor
        block = particle_203
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_204]
        type = ADComputeElasticityTensor
        block = particle_204
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_205]
        type = ADComputeElasticityTensor
        block = particle_205
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_206]
        type = ADComputeElasticityTensor
        block = particle_206
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_207]
        type = ADComputeElasticityTensor
        block = particle_207
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_208]
        type = ADComputeElasticityTensor
        block = particle_208
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_209]
        type = ADComputeElasticityTensor
        block = particle_209
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_210]
        type = ADComputeElasticityTensor
        block = particle_210
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_211]
        type = ADComputeElasticityTensor
        block = particle_211
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_212]
        type = ADComputeElasticityTensor
        block = particle_212
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_213]
        type = ADComputeElasticityTensor
        block = particle_213
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_214]
        type = ADComputeElasticityTensor
        block = particle_214
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_215]
        type = ADComputeElasticityTensor
        block = particle_215
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_216]
        type = ADComputeElasticityTensor
        block = particle_216
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_217]
        type = ADComputeElasticityTensor
        block = particle_217
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_218]
        type = ADComputeElasticityTensor
        block = particle_218
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_219]
        type = ADComputeElasticityTensor
        block = particle_219
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_220]
        type = ADComputeElasticityTensor
        block = particle_220
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_221]
        type = ADComputeElasticityTensor
        block = particle_221
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_222]
        type = ADComputeElasticityTensor
        block = particle_222
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_223]
        type = ADComputeElasticityTensor
        block = particle_223
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_224]
        type = ADComputeElasticityTensor
        block = particle_224
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_225]
        type = ADComputeElasticityTensor
        block = particle_225
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_226]
        type = ADComputeElasticityTensor
        block = particle_226
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_227]
        type = ADComputeElasticityTensor
        block = particle_227
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_228]
        type = ADComputeElasticityTensor
        block = particle_228
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_229]
        type = ADComputeElasticityTensor
        block = particle_229
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_230]
        type = ADComputeElasticityTensor
        block = particle_230
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_231]
        type = ADComputeElasticityTensor
        block = particle_231
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_232]
        type = ADComputeElasticityTensor
        block = particle_232
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_233]
        type = ADComputeElasticityTensor
        block = particle_233
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_234]
        type = ADComputeElasticityTensor
        block = particle_234
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_235]
        type = ADComputeElasticityTensor
        block = particle_235
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_236]
        type = ADComputeElasticityTensor
        block = particle_236
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_237]
        type = ADComputeElasticityTensor
        block = particle_237
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_238]
        type = ADComputeElasticityTensor
        block = particle_238
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_239]
        type = ADComputeElasticityTensor
        block = particle_239
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_240]
        type = ADComputeElasticityTensor
        block = particle_240
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_241]
        type = ADComputeElasticityTensor
        block = particle_241
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
    []
    [elasticity_particle_242]
        type = ADComputeElasticityTensor
        block = particle_242
        fill_method = symmetric9
        C_ijkl = '24980 8190 5800 19580 5900 17890 5150 4060 6900'
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
