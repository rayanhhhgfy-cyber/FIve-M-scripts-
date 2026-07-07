function AddTextEntry(key, value)
    Citizen.InvokeNative(GetHashKey("ADD_TEXT_ENTRY"), key, value)
end

Citizen.CreateThread(function()
    AddTextEntry("1200RT", "BMW R1200RT Police")
    AddTextEntry("bmwrp", "BMW R Police")
    AddTextEntry("hpbikes", "HP Police Bike")
    AddTextEntry("pbike", "Police Bike")
    AddTextEntry("zzninja33", "Kawasaki Ninja Police")
end)
