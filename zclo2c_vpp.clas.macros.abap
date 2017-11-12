*"* use this source file for any macro definitions you need
*"* in the implementation part of the class

define addtowhere .
  if &1 is initial .
    &1 = &3 .
  else.
    concatenate &1 &2 &3 into &1 separated by space.
  endif.
end-of-definition .
