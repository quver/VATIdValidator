Pod::Spec.new do |spec|
spec.name               = "VATIdValidator"
spec.version            = "1.0.0"
spec.summary            = "Polish VAT ID validator"
spec.description        = "Polish VAT Identification (NIP) number validator."
spec.homepage           = "https://github.com/quver/VATIdValidator"
spec.license            = { :type => "MIT", :file => "LICENSE" }
spec.author             = { "Paweł Bednorz" => "pawel@quver.pl" }
spec.documentation_url  = "https://quver.github.io/VATIdValidator/index.html"
spec.platforms          = { :ios => "11.0", :osx => "10.13", :watchos => "5.0" }
spec.swift_version      = "5.1"
spec.source             = { :git => "https://github.com/quver/VATIdValidator.git", :tag => "#{spec.version}" }
spec.source_files       = "Sources/VATIdValidator/**/*.swift"
end
