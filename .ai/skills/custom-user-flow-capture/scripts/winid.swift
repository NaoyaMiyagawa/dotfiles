// Prints the CGWindowID of the largest on-screen window owned by the given app name.
import CoreGraphics
let owner = CommandLine.arguments[1]
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as! [[String: Any]]
let best = list
  .filter { ($0[kCGWindowOwnerName as String] as? String) == owner && ($0[kCGWindowLayer as String] as? Int) == 0 }
  .max { a, b in
    let ra = a[kCGWindowBounds as String] as! [String: Double], rb = b[kCGWindowBounds as String] as! [String: Double]
    return ra["Width"]! * ra["Height"]! < rb["Width"]! * rb["Height"]!
  }
print(best?[kCGWindowNumber as String] ?? "")
