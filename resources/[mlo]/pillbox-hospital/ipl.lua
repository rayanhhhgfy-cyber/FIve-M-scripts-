local L0_1, L1_1
L0_1 = Citizen
L0_1 = L0_1.CreateThread
function L1_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = GetInteriorAtCoords
  L1_2 = 311.2546
  L2_2 = -592.4204
  L3_2 = 42.32737
  L0_2 = L0_2(L1_2, L2_2, L3_2)
  L1_2 = IsValidInterior
  L2_2 = L0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = RemoveIpl
    L2_2 = "rc12b_fixed"
    L1_2(L2_2)
    L1_2 = RemoveIpl
    L2_2 = "rc12b_destroyed"
    L1_2(L2_2)
    L1_2 = RemoveIpl
    L2_2 = "rc12b_default"
    L1_2(L2_2)
    L1_2 = RemoveIpl
    L2_2 = "rc12b_hospitalinterior_lod"
    L1_2(L2_2)
    L1_2 = RemoveIpl
    L2_2 = "rc12b_hospitalinterior"
    L1_2(L2_2)
    L1_2 = RefreshInterior
    L2_2 = L0_2
    L1_2(L2_2)
  end
end
L0_1(L1_1)
