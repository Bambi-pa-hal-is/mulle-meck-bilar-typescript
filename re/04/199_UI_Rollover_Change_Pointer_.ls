property outcurs, incurs, incursSet, customImage, customMask, oldcursor, useCustom

on translate_cursor me, setting, image, mask, Custom
  if Custom then
    set val to [member(image), member(mask)]
    return val
  end if
  return setting
end

on beginSprite me
  set oldcursor to the cursor of sprite the spriteNum of me
  set val to translate_cursor(me, the incursSet of me, customImage, customMask, useCustom)
  set the cursor of sprite the spriteNum of me to val
end

on endSprite me
  set the cursor of sprite the spriteNum of me to oldcursor
end

on getPropertyDescriptionList
  set p_list to [#incursSet: [#comment: "Pointer Image:", #format: #cursor, #default: 1], #useCustom: [#comment: "Use Custom Pointer:", #format: #boolean, #default: 0], #customImage: [#comment: "Custom Image:", #format: #bitmap, #default: member(1)], #customMask: [#comment: "Custom Mask:", #format: #bitmap, #default: member(1)]]
  return p_list
end

on getBehaviorDescription
  return "Changes the pointer image when the pointer rolls over the current sprite. Choose one of the pointers included with Director, or specify a 1-bit bitmapped cast member." & RETURN & "PARAMETERS:" & RETURN & "¥ Pointer Image - Choose one of Director's included pointers." & RETURN & "¥ Use Custom Pointer - Turn this option on to specify a cast member instead of an included pointer." & RETURN & "¥ Custom Image  - ( optional ) Choose a cast member to use as the pointer image.  This choice is ignored unless Use Custom Pointer is on." & RETURN & "¥ Custom Mask - ( optional ) Choose a cast member to use as mask image."
end
