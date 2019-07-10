--  Message part strings and methods for printing

local messageVerbs = {
    " procured ",
    " got ",
    " got hold of ",
    " gained ",
    " earned ",
    " found ",
    " obtained ",
    " picked up ",
    " collected ",
    " retrieved ",
    " secured "
};

--  string "who", string "description", whichGame() int value fromWhere
local function print(who, description, fromWhere)
    local location = nil;

    if fromWhere == 0 then location = "Hyrule"
    elseif fromWhere == 1 then location = "Zebes" end;

    message(who .. messageVerbs[math.random(1, #messageVerbs)] .. description .. " from " .. location);
end;



return {
    print = print
};