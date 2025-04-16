--[[
Copyright (c) 2022 Thorny

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]

local function FillSpellTable(spellTable)
    --Reraise
    spellTable[135] = function(targetId)
        return 3600;
    end
    
    --Reraise II
    spellTable[141] = function(targetId)
        return 3600;
    end
    
    --Reraise III
    spellTable[142] = function(targetId)
        return 3600;
    end

    --Enlight
    spellTable[310] = function(targetId)
        return 180;
    end
    
    --Reraise IV
    spellTable[848] = function(targetId)
        return 3600;
    end
    
    --Enlight II
    spellTable[855] = function(targetId)
        return 180;
    end

end

return FillSpellTable;