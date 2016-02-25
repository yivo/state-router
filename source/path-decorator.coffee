# TODO Bugs with splat param
class PathDecorator extends CoreObject

  @params 'paramPreprocessor', 'reEscape', 'escapeReplacement'

  reEscape:           /[\-{}\[\]+?.,\\\^$|#\s]/g
  reParam:            /(\()?(.)?(\*)?:(\w+)\)?/g
  escapeReplacement:  '\\$&'

  paramPreprocessor: (match, optional, token, splat, param) ->
    ret = "(?:#{token || ''}(?<#{param}>" + (if splat then '[^?]*?' else '[^/?]+') + '))'
    if optional then "(?:#{ret})?" else ret

  # @example Required param
  #   Path:    blog/post/:id
  #   XRegExp: blog\/post\/(?<id>[^\/?]+)
  #   RegExp:  blog\/post\/([^\/?]+)
  #
  # @example Optional param
  #   Path:    users(/:searchConditions)
  #   Steps:
  #     1) Optional segment: users(?:/:searchConditions)?
  #     2) Parameter:        users(?:/(?<searchConditions>[^/?]+))?
  #   XRegExp: users(?:/(?<searchConditions>[^/?]+))?
  #   RegExp:  users(?:\/([^\/?]+))?
  #
  # @example Required splat param
  #   Path:    download/*:filepath
  #   XRegExp: download/(?<filepath>[^?]*?)
  #   RegExp:  download\/([^?]*?)
  #
  # @example Optional splat param
  #   Path:    directory/view/root(/*:path)
  #   Steps:
  #     1) Optional segment: directory/view/root(?:/*:path)?
  #     2) Parameter:        directory/view/root(?:/(?<path>[^?]*?))?
  #   XRegExp: directory/view/root(?:/(?<path>[^?]*?))?
  #   RegExp:  directory\/view\/root(?:\/([^?]*?))?
  preprocessParams: (path) ->
    @replaceParams(path, @paramPreprocessor)

  replaceParams: (path, replacement) ->
    path.replace(@reParam, replacement)

  escape: (path) ->
    path.replace(@reEscape, @escapeReplacement)
