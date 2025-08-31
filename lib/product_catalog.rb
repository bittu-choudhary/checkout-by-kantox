class ProductCatalog
  def initialize(products: [])
    @products = {}
    products.each { |product| add(product) }
  end

  def find(code)
    @products[code]
  end

  def add(product)
    @products[product.code] = product
  end
end
