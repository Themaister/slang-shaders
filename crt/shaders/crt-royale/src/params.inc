//#define HARDCODE_SETTINGS

#ifndef HARDCODE_SETTINGS
//  Set shader params for all passes here:
#pragma parameter crt_gamma "Simulated CRT Gamma" 2.5 1.0 5.0 0.025
#define crt_gamma global.crt_gamma
#pragma parameter lcd_gamma "Your Display Gamma" 2.2 1.0 5.0 0.025
#define lcd_gamma global.lcd_gamma
#pragma parameter levels_contrast "Contrast" 1.0 0.0 4.0 0.015625
#define levels_contrast global.levels_contrast
#pragma parameter halation_weight "Halation Weight" 0.0 0.0 1.0 0.005
#pragma parameter diffusion_weight "Diffusion Weight" 0.075 0.0 1.0 0.005
#pragma parameter bloom_underestimate_levels "Bloom - Underestimate Levels" 0.8 0.0 5.0 0.01
#define bloom_underestimate_levels global.bloom_underestimate_levels
#pragma parameter bloom_excess "Bloom - Excess" 0.0 0.0 1.0 0.005
#pragma parameter beam_min_sigma "Beam - Min Sigma" 0.02 0.005 1.0 0.005
#define beam_min_sigma global.beam_min_sigma
#pragma parameter beam_max_sigma "Beam - Max Sigma" 0.3 0.005 1.0 0.005
#define beam_max_sigma global.beam_max_sigma
#pragma parameter beam_spot_power "Beam - Spot Power" 0.33 0.01 16.0 0.01
#define beam_spot_power global.beam_spot_power
#pragma parameter beam_min_shape "Beam - Min Shape" 2.0 2.0 32.0 0.1
#define beam_min_shape global.beam_min_shape
#pragma parameter beam_max_shape "Beam - Max Shape" 4.0 2.0 32.0 0.1
#define beam_max_shape global.beam_max_shape
#pragma parameter beam_shape_power "Beam - Shape Power" 0.25 0.01 16.0 0.01
#define beam_shape_power global.beam_shape_power
#pragma parameter beam_horiz_filter "Beam - Horiz Filter" 0.0 0.0 2.0 1.0
#define beam_horiz_filter global.beam_horiz_filter
#pragma parameter beam_horiz_sigma "Beam - Horiz Sigma" 0.35 0.0 0.67 0.005
#define beam_horiz_sigma global.beam_horiz_sigma
#pragma parameter beam_horiz_linear_rgb_weight "Beam - Horiz Linear RGB Weight" 1.0 0.0 1.0 0.01
#pragma parameter convergence_offset_x_r "Convergence - Offset X Red" 0.0 -4.0 4.0 0.05
#define convergence_offset_x_r global.convergence_offset_x_r
#pragma parameter convergence_offset_x_g "Convergence - Offset X Green" 0.0 -4.0 4.0 0.05
#define convergence_offset_x_g global.convergence_offset_x_g
#pragma parameter convergence_offset_x_b "Convergence - Offset X Blue" 0.0 -4.0 4.0 0.05
#define convergence_offset_x_b global.convergence_offset_x_b
#pragma parameter convergence_offset_y_r "Convergence - Offset Y Red" 0.0 -2.0 2.0 0.05
#define convergence_offset_y_r global.convergence_offset_y_r
#pragma parameter convergence_offset_y_g "Convergence - Offset Y Green" 0.0 -2.0 2.0 0.05
#define convergence_offset_y_g global.convergence_offset_y_g
#pragma parameter convergence_offset_y_b "Convergence - Offset Y Blue" 0.0 -2.0 2.0 0.05
#define convergence_offset_y_b global.convergence_offset_y_b
#pragma parameter mask_type "Mask - Type" 1.0 0.0 2.0 1.0
#define mask_type global.mask_type
#pragma parameter mask_sample_mode_desired "Mask - Sample Mode" 0.0 0.0 2.0 1.0   //  Consider blocking mode 2.
#define mask_sample_mode_desired global.mask_sample_mode_desired
#pragma parameter mask_specify_num_triads "Mask - Specify Number of Triads" 0.0 0.0 1.0 1.0
#pragma parameter mask_triad_size_desired "Mask - Triad Size Desired" 3.0 1.0 18.0 0.125
#pragma parameter mask_num_triads_desired "Mask - Number of Triads Desired" 480.0 342.0 1920.0 1.0
#pragma parameter aa_subpixel_r_offset_x_runtime "AA - Subpixel R Offset X" -0.333333333 -0.333333333 0.333333333 0.333333333
#define aa_subpixel_r_offset_x_runtime global.aa_subpixel_r_offset_x_runtime
#pragma parameter aa_subpixel_r_offset_y_runtime "AA - Subpixel R Offset Y" 0.0 -0.333333333 0.333333333 0.333333333
#define aa_subpixel_r_offset_y_runtime global.aa_subpixel_r_offset_y_runtime
#pragma parameter aa_cubic_c "AA - Cubic Sharpness" 0.5 0.0 4.0 0.015625
#define aa_cubic_c global.aa_cubic_c
#pragma parameter aa_gauss_sigma "AA - Gaussian Sigma" 0.5 0.0625 1.0 0.015625
#define aa_gauss_sigma global.aa_gauss_sigma
#pragma parameter geom_mode_runtime "Geometry - Mode" 0.0 0.0 3.0 1.0
#define geom_mode_runtime global.geom_mode_runtime
#pragma parameter geom_radius "Geometry - Radius" 2.0 0.16 1024.0 0.1
#define geom_radius global.geom_radius
#pragma parameter geom_view_dist "Geometry - View Distance" 2.0 0.5 1024.0 0.25
#define geom_view_dist global.geom_view_dist
#pragma parameter geom_tilt_angle_x "Geometry - Tilt Angle X" 0.0 -3.14159265 3.14159265 0.017453292519943295
#define geom_tilt_angle_x global.geom_tilt_angle_x
#pragma parameter geom_tilt_angle_y "Geometry - Tilt Angle Y" 0.0 -3.14159265 3.14159265 0.017453292519943295
#define geom_tilt_angle_y global.geom_tilt_angle_y
#pragma parameter geom_aspect_ratio_x "Geometry - Aspect Ratio X" 432.0 1.0 512.0 1.0
#define geom_aspect_ratio_x global.geom_aspect_ratio_x
#pragma parameter geom_aspect_ratio_y "Geometry - Aspect Ratio Y" 329.0 1.0 512.0 1.0
#define geom_aspect_ratio_y global.geom_aspect_ratio_y
#pragma parameter geom_overscan_x "Geometry - Overscan X" 1.0 0.00390625 4.0 0.00390625
#define geom_overscan_x global.geom_overscan_x
#pragma parameter geom_overscan_y "Geometry - Overscan Y" 1.0 0.00390625 4.0 0.00390625
#define geom_overscan_y global.geom_overscan_y
#pragma parameter border_size "Border - Size" 0.015 0.0000001 0.5 0.005
#define border_size global.border_size
#pragma parameter border_darkness "Border - Darkness" 2.0 0.0 16.0 0.0625
#define border_darkness global.border_darkness
#pragma parameter border_compress "Border - Compression" 2.5 1.0 64.0 0.0625
#define border_compress global.border_compress
#pragma parameter interlace_bff "Interlacing - Bottom Field First" 0.0 0.0 1.0 1.0
//#define interlace_bff global.interlace_bff
#pragma parameter interlace_1080i "Interlace - Detect 1080i" 0.0 0.0 1.0 1.0
#define interlace_1080i global.interlace_1080i
#endif
