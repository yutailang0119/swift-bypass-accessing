@attached(peer, names: prefixed(___), named(___init))
public macro BypassAccess() = #externalMacro(module: "BypassAccessingMacros", type: "BypassAccessMacro")
