const Package = require(script.Parent._Index["skatingii_swiftpacket@0.1.4"]["swiftpacket"])

export type Options = Package.Options
export type Connection = Package.Connection
export type Signal<A...> = Package.Signal<A...>
export type Request<A..., B...> = Package.Request<A..., B...>
export type Event<A...> = Package.Event<A...>
export type Fields = Package.Fields
export type SwiftPacket = Package.SwiftPacket

return Package
