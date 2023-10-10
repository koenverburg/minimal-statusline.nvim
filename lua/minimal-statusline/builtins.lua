local builtins = {}

builtins.file_info = "%r%h%w%q" -- flags: r:RO,h:help,w:preview,q:quickfix list/loc list
builtins.line = "%l"
builtins.modified = "%m"
builtins.number_of_lines = "%L"
builtins.ruler = "[%7(%l/%3L%):%2c %P]" -- ruler
builtins.space = " "
builtins.split = "%="

return builtins
