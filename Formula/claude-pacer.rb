class ClaudePacer < Formula
  desc "Menu-bar pace for your Claude subscription: will it last until the reset, and what to change"
  homepage "https://github.com/dkremsa/claude-pacer"
  url "https://github.com/dkremsa/claude-pacer/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "a2cb4cd513cdb0d1a7fdc9c776f761388c00dfcaf51950c9cdc694aa61381f5d"
  license "MIT"

  depends_on "node"
  depends_on :macos

  def install
    app = prefix/"Claude Pacer.app"
    (app/"Contents/MacOS").mkpath
    (app/"Contents/Resources").mkpath
    system "swiftc", "-O", "-o", app/"Contents/MacOS/Pacer", "Pacer.swift"
    system "swiftc", "-O", "-o", "pacer-icon", "icon.swift"
    mkdir "Pacer.iconset"
    system "./pacer-icon", "Pacer.iconset"
    system "iconutil", "-c", "icns", "Pacer.iconset", "-o", app/"Contents/Resources/Pacer.icns"
    (app/"Contents/Info.plist").write <<~PLIST
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0"><dict>
        <key>CFBundleIdentifier</key><string>com.claude-pacer</string>
        <key>CFBundleName</key><string>Claude Pacer</string>
        <key>CFBundleDisplayName</key><string>Claude Pacer</string>
        <key>CFBundleExecutable</key><string>Pacer</string>
        <key>CFBundleIconFile</key><string>Pacer</string>
        <key>CFBundlePackageType</key><string>APPL</string>
        <key>CFBundleShortVersionString</key><string>#{version}</string>
        <key>LSUIElement</key><true/>
        <key>LSMinimumSystemVersion</key><string>13.0</string>
      </dict></plist>
    PLIST
    libexec.install "pacer.mjs"
    (bin/"claude-pacer").write <<~SH
      #!/bin/sh
      exec "#{Formula["node"].opt_bin}/node" "#{libexec}/pacer.mjs" "$@"
    SH
  end

  service do
    run [Formula["node"].opt_bin/"node", opt_libexec/"pacer.mjs", "tick"]
    run_type :interval
    interval 600
    log_path var/"log/claude-pacer.log"
    error_log_path var/"log/claude-pacer.log"
  end

  def caveats
    <<~EOS
      Start the 10-minute sampler (survives reboots):
        brew services start claude-pacer

      Put the app where Login Items can see it, and open it:
        cp -R "#{opt_prefix}/Claude Pacer.app" /Applications/
        open "/Applications/Claude Pacer.app"

      Start at login: System Settings → General → Login Items & Extensions → + → Claude Pacer.
      Needs a Claude Code login (reads the same credential /usage uses).
    EOS
  end

  test do
    assert_match "usage: pacer", shell_output("#{bin}/claude-pacer help", 1)
  end
end
