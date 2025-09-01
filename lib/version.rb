# Checkout System By Kantox
module CheckoutByKantox
  VERSION = "1.0.0"
  DESCRIPTION = "Checkout system with with inventory management and dynamic pricing rules"

  def self.version_info
    {
      version: VERSION,
      description: DESCRIPTION,
      ruby_version: RUBY_VERSION,
      test_coverage: "98.55%"
    }
  end

  def self.banner
    <<~BANNER
      ╔══════════════════════════════════════════════════════════════╗
      ║                  Checkout System By Kantox                   ║
      ║                        v#{VERSION}                                ║
      ║                                                              ║
      ║                Checkout with dynamic pricing                 ║
      ║                                                              ║
      ╚══════════════════════════════════════════════════════════════╝
    BANNER
  end
end
