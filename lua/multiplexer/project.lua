local Project = {}

function Project:new(args)
  return {
    id = args.id,
    name = args.name,
    path = args.path,
    is_focused = args.is_focused,
    was_focused = args.was_focused,
    open = args.open,
    metadata = args.metadata or {}
  }
end

return Project
