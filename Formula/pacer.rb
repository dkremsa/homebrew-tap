class Pacer < Formula
  desc "Menu-bar pace for AI coding subscriptions: will they last until their reset"
  homepage "https://github.com/dkremsa/claude-pacer"
  url "https://github.com/dkremsa/claude-pacer/archive/refs/tags/v2.0.0.tar.gz"
  sha256 "6d19c81cc37c118ef6315eb2af57ae42a50e10df2ddcea0fb13bb05dd1a7d034"
  license "MIT"

  depends_on "node"
  depends_on :macos

  # Renamed from `claude-pacer` at v2.0.0 — it is not Claude-only any more. `Aliases/claude-pacer` keeps the old
  # install command resolving here; an already-installed `claude-pacer` keg does NOT upgrade across the rename and
  # has to be uninstalled first. The BUNDLE ID stays `com.claude-pacer` on purpose: it is what macOS keys Login
  # Items and notification permission on, and the repo, launchd label and data dir keep the old name with it.
  def install
    app = prefix/"Pacer.app"
    (app/"Contents/MacOS").mkpath
    (app/"Contents/Resources").mkpath
    system "swiftc", "-O", "-o", app/"Contents/MacOS/Pacer", "Pacer.swift"
    system "swiftc", "-O", "-o", "pacer-icon", "icon.swift"
    mkdir "Pacer.iconset"
    system "./pacer-icon", "Pacer.iconset"
    system "iconutil", "-c", "icns", "Pacer.iconset", "-o", app/"Contents/Resources/Pacer.icns"
    # 🚨 KEEP IN STEP WITH `build.sh` in the claude-pacer repo, which writes this same Info.plist for a local
    # build. One home is impossible — a formula may not write to /Applications or ~/Library/LaunchAgents, which
    # is most of what build.sh does — so these two copies name each other instead. They had already drifted:
    # build.sh said CFBundleName "Pacer" while this said "Claude Pacer", months after the rename.
    (app/"Contents/Info.plist").write <<~PLIST
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0"><dict>
        <key>CFBundleIdentifier</key><string>com.claude-pacer</string>
        <key>CFBundleName</key><string>Pacer</string>
        <key>CFBundleDisplayName</key><string>Pacer</string>
        <key>CFBundleExecutable</key><string>Pacer</string>
        <key>CFBundleIconFile</key><string>Pacer</string>
        <key>CFBundlePackageType</key><string>APPL</string>
        <key>CFBundleShortVersionString</key><string>#{version}</string>
        <key>LSUIElement</key><true/>
        <key>LSMinimumSystemVersion</key><string>13.0</string>
      </dict></plist>
    PLIST
    libexec.install "pacer.mjs"
    (bin/"pacer").write <<~SH
      #!/bin/sh
      exec "#{Formula["node"].opt_bin}/node" "#{libexec}/pacer.mjs" "$@"
    SH
  end

  service do
    run [Formula["node"].opt_bin/"node", opt_libexec/"pacer.mjs", "tick"]
    run_type :interval
    interval 600
    log_path var/"log/pacer.log"
    error_log_path var/"log/pacer.log"
  end

  def caveats
    <<~EOS
      Start the 10-minute sampler (survives reboots):
        brew services start pacer

      Put the app where Login Items can see it, and open it:
        cp -R "#{opt_prefix}/Pacer.app" /Applications/
        open "/Applications/Pacer.app"

      Upgrading from claude-pacer? Remove it first: brew uninstall claude-pacer

      Start at login: System Settings → General → Login Items & Extensions → + → Pacer.
      Reads the logins already on this Mac — Claude Code, Codex, Antigravity, Cursor.
      A provider you are not logged into costs nothing and shows nothing.
    EOS
  end

  test do
    assert_match "usage: pacer", shell_output("#{bin}/pacer help", 1)
  end
end
