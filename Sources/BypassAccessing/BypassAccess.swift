@attached(peer, names: prefixed(___), named(___init))
public macro BypassAccess(isIfDebug: Bool = true) = #externalMacro(module: "BypassAccessingMacros", type: "BypassAccessMacro")
