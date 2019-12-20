vec3 mask_weights(vec2 coord, float mask_intensity, int phosphor_layout){
   vec3 weights = vec3(0.,0.,0.);
   float intens = 1.;
   float inv = 1.-mask_intensity;
   vec3 green   = vec3(inv, intens, inv);
   vec3 magenta = vec3(intens,inv,intens);
   vec3 black   = vec3(inv,inv,inv);
   vec3 red     = vec3(intens,inv,inv);
   vec3 yellow  = vec3(intens,inv,intens);
   vec3 cyan    = vec3(inv,intens,intens);
   vec3 blue    = vec3(inv,inv,intens);
   int w, z = 0;
   
   vec3 aperture_weights = mix(magenta, green, floor(mod(coord.x, 2.0)));

   if(phosphor_layout == 1){
      // classic aperture for RGB panels; good for 1080p, too small for 4K+
      // aka aperture_1_2_bgr
      weights  = aperture_weights;
   }

   else if(phosphor_layout == 2){
      // 2x2 shadow mask for RGB panels; good for 1080p, too small for 4K+
      // aka delta_1_2x1_bgr
      vec3 inverse_aperture = mix(green, magenta, floor(mod(coord.x, 2.0)));
      weights               = mix(aperture_weights, inverse_aperture, floor(mod(coord.y, 2.0)));
   }

   else if(phosphor_layout == 3){
      // slot mask for RGB panels; looks okay at 1080p, looks better at 4K
      vec3 slotmask[3][4] = {
         {magenta, green, black,   black},
         {magenta, green, magenta, green},
         {black,   black, magenta, green}
      };
      
      // find the vertical index
      w = int(floor(mod(coord.y, 3.0)));

      // find the horizontal index
      z = int(floor(mod(coord.x, 4.0)));

      // use the indexes to find which color to apply to the current pixel
      weights = slotmask[w][z];
   }

   if(phosphor_layout == 4){
      // classic aperture for RBG panels; good for 1080p, too small for 4K+
      weights  = mix(yellow, blue, floor(mod(coord.x, 2.0)));
   }

   else if(phosphor_layout == 5){
      // 2x2 shadow mask for RBG panels; good for 1080p, too small for 4K+
      vec3 inverse_aperture = mix(blue, yellow, floor(mod(coord.x, 2.0)));
      weights               = mix(mix(yellow, blue, floor(mod(coord.x, 2.0))), inverse_aperture, floor(mod(coord.y, 2.0)));
   }
   
   else if(phosphor_layout == 6){
      // aperture_1_4_rgb; good for simulating lower 
      vec3 ap4[4] = vec3[](red, green, blue, black);
      
      z = int(floor(mod(coord.x, 4.0)));
      
      weights = ap4[z];
   }
   
   else if(phosphor_layout == 7){
      // aperture_2_5_bgr
      vec3 ap3[5] = vec3[](red, magenta, blue, green, green);
      
      z = int(floor(mod(coord.x, 5.0)));
      
      weights = ap3[z];
   }
   
   else if(phosphor_layout == 8){
      // aperture_3_6_rgb
      
      vec3 big_ap[7] = vec3[](red, red, yellow, green, cyan, blue, blue);
      
      w = int(floor(mod(coord.x, 7.)));
      
      weights = big_ap[w];
   }
   
   else if(phosphor_layout == 9){
      // reduced TVL aperture for RGB panels
      // aperture_2_4_rgb
      
      vec3 big_ap_rgb[4] = vec3[](red, yellow, cyan, blue);
      
      w = int(floor(mod(coord.x, 4.)));
      
      weights = big_ap_rgb[w];
   }
   
   else if(phosphor_layout == 10){
      // reduced TVL aperture for RBG panels
      
      vec3 big_ap_rbg[4] = vec3[](red, magenta, cyan, green);
      
      w = int(floor(mod(coord.x, 4.)));
      
      weights = big_ap_rbg[w];
   }
   
   else if(phosphor_layout == 11){
      // delta_1_4x1_rgb; dunno why this is called 4x1 when it's obviously 4x2 /shrug
      vec3 delta1[2][4] = {
         {red,  green, blue, black},
         {blue, black, red,  green}
      };
      
      w = int(floor(mod(coord.y, 2.0)));
      z = int(floor(mod(coord.x, 4.0)));
      
      weights = delta1[w][z];
   }
   
   else if(phosphor_layout == 12){
      // delta_2_4x1_rgb
      vec3 delta[2][4] = {
         {red, yellow, cyan, blue},
         {cyan, blue, red, yellow}
      };
      
      w = int(floor(mod(coord.y, 2.0)));
      z = int(floor(mod(coord.x, 4.0)));
      
      weights = delta[w][z];
   }
   
   else if(phosphor_layout == 13){
      // delta_2_4x2_rgb
      vec3 delta[4][4] = {
         {red,  yellow, cyan, blue},
         {red,  yellow, cyan, blue},
         {cyan, blue,   red,  yellow},
         {cyan, blue,   red,  yellow}
      };
      
      w = int(floor(mod(coord.y, 4.0)));
      z = int(floor(mod(coord.x, 4.0)));
      
      weights = delta[w][z];
   }

   else if(phosphor_layout == 14){
      // slot mask for RGB panels; too low-pitch for 1080p, looks okay at 4K, but wants 8K+
      vec3 slotmask[3][6] = {
         {magenta, green, black, black,   black, black},
         {magenta, green, black, magenta, green, black},
         {black,   black, black, magenta, green, black}
      };
      
      // find the vertical index
      w = int(floor(mod(coord.y, 3.0)));

      // find the horizontal index
      z = int(floor(mod(coord.x, 6.0)));

      // use the indexes to find which color to apply to the current pixel
      weights = slotmask[w][z];
   }
   
   else if(phosphor_layout == 15){
      // slot_2_4x4_rgb
      vec3 slot2[4][8] = {
         {red,   yellow, cyan,  blue,  red,   yellow, cyan,  blue },
         {red,   yellow, cyan,  blue,  black, black,  black, black},
         {red,   yellow, cyan,  blue,  red,   yellow, cyan,  blue },
         {black, black,  black, black, red,   yellow, cyan,  blue }
      };
   
      w = int(floor(mod(coord.y, 4.0)));
      z = int(floor(mod(coord.x, 8.0)));
      
      weights = slot2[w][z];
   }

   else if(phosphor_layout == 16){
      // slot mask for RBG panels; too low-pitch for 1080p, looks okay at 4K, but wants 8K+
      vec3 slotmask[3][4] = {
         {yellow, blue,  black,  black},
         {yellow, blue,  yellow, blue},
         {black,  black, yellow, blue}
      };
      
      // find the vertical index
      w = int(floor(mod(coord.y, 3.0)));

      // find the horizontal index
      z = int(floor(mod(coord.x, 4.0)));

      // use the indexes to find which color to apply to the current pixel
      weights = slotmask[w][z];
   }
   
   else if(phosphor_layout == 17){
      // slot_2_5x4_bgr
      vec3 slot2[4][10] = {
         {red,   magenta, blue,  green, green, red,   magenta, blue,  green, green},
         {black, blue,    blue,  green, green, red,   red,     black, black, black},
         {red,   magenta, blue,  green, green, red,   magenta, blue,  green, green},
         {red,   red,     black, black, black, black, blue,    blue,  green, green}
      };
   
      w = int(floor(mod(coord.y, 4.0)));
      z = int(floor(mod(coord.x, 10.0)));
      
      weights = slot2[w][z];
   }
   
   else if(phosphor_layout == 18){
      // same as above but for RBG panels
      vec3 slot2[4][10] = {
         {red,   yellow, green, blue,  blue,  red,   yellow, green, blue,  blue },
         {black, green,  green, blue,  blue,  red,   red,    black, black, black},
         {red,   yellow, green, blue,  blue,  red,   yellow, green, blue,  blue },
         {red,   red,    black, black, black, black, green,  green, blue,  blue }
      };
   
      w = int(floor(mod(coord.y, 4.0)));
      z = int(floor(mod(coord.x, 10.0)));
      
      weights = slot2[w][z];
   }
   
   else if(phosphor_layout == 19){
      // slot_3_7x6_rgb
      vec3 slot[6][14] = {
         {red,   red,   yellow, green, cyan,  blue,  blue,  red,   red,   yellow, green,  cyan,  blue,  blue},
         {red,   red,   yellow, green, cyan,  blue,  blue,  red,   red,   yellow, green,  cyan,  blue,  blue},
         {red,   red,   yellow, green, cyan,  blue,  blue,  black, black, black,  black,  black, black, black},
         {red,   red,   yellow, green, cyan,  blue,  blue,  red,   red,   yellow, green,  cyan,  blue,  blue},
         {red,   red,   yellow, green, cyan,  blue,  blue,  red,   red,   yellow, green,  cyan,  blue,  blue},
         {black, black, black,  black, black, black, black, black, red,   red,    yellow, green, cyan,  blue}
      };
      
      w = int(floor(mod(coord.y, 6.0)));
      z = int(floor(mod(coord.x, 14.0)));
      
      weights = slot[w][z];
   }

   return weights;
}