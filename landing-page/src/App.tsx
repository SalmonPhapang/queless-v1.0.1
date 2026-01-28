import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Smartphone, ShoppingBag, Clock, CreditCard, Menu, X, Beer, Utensils, Truck, MapPin, CheckCircle, ChevronRight, Store } from 'lucide-react';

function App() {
  const [isMenuOpen, setIsMenuOpen] = React.useState(false);
  const [isPartnerModalOpen, setIsPartnerModalOpen] = React.useState(false);

  return (
    <div className="min-h-screen bg-light font-sans text-dark overflow-x-hidden">
      {/* Navigation */}
      <nav className="fixed w-full bg-white/80 backdrop-blur-md z-50 border-b border-gray-100">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center">
              <span className="text-2xl font-bold text-primary">Queless</span>
            </div>
            
            {/* Desktop Menu */}
            <div className="hidden md:flex items-center space-x-8">
              <a href="#features" className="text-gray-600 hover:text-primary transition-colors">Features</a>
              <a href="#how-it-works" className="text-gray-600 hover:text-primary transition-colors">How it works</a>
              <a href="#locations" className="text-gray-600 hover:text-primary transition-colors">Locations</a>
              <button className="bg-primary hover:bg-secondary text-white px-6 py-2 rounded-full font-medium transition-colors shadow-lg shadow-primary/30">
                Get the App
              </button>
            </div>

            {/* Mobile Menu Button */}
            <div className="md:hidden">
              <button onClick={() => setIsMenuOpen(!isMenuOpen)} className="text-gray-600">
                {isMenuOpen ? <X size={24} /> : <Menu size={24} />}
              </button>
            </div>
          </div>
        </div>

        {/* Mobile Menu */}
        {isMenuOpen && (
          <div className="md:hidden bg-white border-b border-gray-100">
            <div className="px-2 pt-2 pb-3 space-y-1 sm:px-3">
              <a href="#features" className="block px-3 py-2 text-gray-600 hover:text-primary">Features</a>
              <a href="#how-it-works" className="block px-3 py-2 text-gray-600 hover:text-primary">How it works</a>
              <a href="#locations" className="block px-3 py-2 text-gray-600 hover:text-primary">Locations</a>
              <button className="w-full mt-4 bg-primary text-white px-6 py-2 rounded-full font-medium">
                Get the App
              </button>
            </div>
          </div>
        )}
      </nav>

      {/* Hero Section */}
      <section className="pt-32 pb-20 lg:pt-48 lg:pb-32 px-4 overflow-hidden">
        <div className="max-w-7xl mx-auto">
          <div className="flex flex-col lg:flex-row items-center">
            <motion.div 
              className="lg:w-1/2 lg:pr-12 text-center lg:text-left"
              initial={{ opacity: 0, x: -50 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.8 }}
            >
              <h1 className="text-4xl lg:text-6xl font-extrabold leading-tight mb-6">
                Your Favorite<br />
                <span className="text-secondary">Drinks & Eats, Delivered.</span>
              </h1>
              <p className="text-xl text-gray-600 mb-8 max-w-2xl mx-auto lg:mx-0">
                South Africa's premier on-demand delivery service. From a cold Castle to a hot meal, Queless brings the good times to your door.
              </p>
              <div className="flex flex-col sm:flex-row gap-4 justify-center lg:justify-start">
                <button className="flex items-center justify-center gap-2 bg-black text-white px-8 py-3 rounded-xl hover:bg-gray-800 transition-colors">
                  <Smartphone size={24} />
                  <div className="text-left">
                    <div className="text-xs">Download on the</div>
                    <div className="text-lg font-bold leading-none">App Store</div>
                  </div>
                </button>
                <button className="flex items-center justify-center gap-2 bg-black text-white px-8 py-3 rounded-xl hover:bg-gray-800 transition-colors">
                  <div className="text-left">
                    <div className="text-xs">GET IT ON</div>
                    <div className="text-lg font-bold leading-none">Google Play</div>
                  </div>
                </button>
              </div>
            </motion.div>

            <motion.div 
              className="lg:w-1/2 mt-16 lg:mt-0 relative"
              initial={{ opacity: 0, x: 50 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.8, delay: 0.2 }}
            >
              <div className="relative mx-auto w-72 h-[600px] bg-black rounded-[3rem] border-8 border-gray-800 shadow-2xl overflow-hidden">
                {/* Screen Content Placeholder */}
                <div className="bg-black h-full w-full overflow-hidden relative flex items-center justify-center p-8">
                  <div className="flex flex-col items-center">
                    <img src="/logo-removebg.png" alt="Queless App" className="w-40 h-40 object-contain mb-4" />
                  </div>
                </div>
              </div>
              
              {/* Decorative Elements */}
              <div className="absolute top-1/2 -right-12 lg:-right-24 w-72 h-72 bg-amber-500/20 rounded-full blur-3xl -z-10"></div>
              <div className="absolute bottom-0 -left-12 lg:-left-24 w-72 h-72 bg-primary/10 rounded-full blur-3xl -z-10"></div>
            </motion.div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="py-20 bg-white">
        <div className="max-w-7xl mx-auto px-4">
          <div className="text-center mb-16">
            <h2 className="text-3xl font-bold mb-4">Why Choose Queless?</h2>
            <p className="text-gray-600 max-w-2xl mx-auto">
              We're bringing the bottle store and the bistro to your doorstep. 
              The fastest way to get your alcohol and food essentials in SA.
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            <FeatureCard 
              icon={<Beer className="w-8 h-8 text-secondary" />}
              title="Alcohol Delivery"
              description="Wide selection of wines, beers, and spirits delivered cold and fast to your door."
            />
            <FeatureCard 
              icon={<Utensils className="w-8 h-8 text-secondary" />}
              title="Local Flavors"
              description="Order from the best local restaurants and food spots in your area. Mzansi's favorites."
            />
            <FeatureCard 
              icon={<Truck className="w-8 h-8 text-secondary" />}
              title="Fast & Reliable"
              description="Real-time tracking and quick delivery across major South African cities."
            />
          </div>
        </div>
      </section>

      {/* How It Works Section */}
      <section id="how-it-works" className="py-20 bg-light">
        <div className="max-w-7xl mx-auto px-4">
          <div className="text-center mb-16">
            <h2 className="text-3xl font-bold mb-4">How It Works</h2>
            <p className="text-gray-600 max-w-2xl mx-auto">
              From craving to comfort in four simple steps.
            </p>
          </div>

          <div className="grid md:grid-cols-4 gap-8">
            <StepCard 
              number="1"
              title="Download App"
              description="Get Queless on iOS or Android and create your account."
            />
            <StepCard 
              number="2"
              title="Browse & Select"
              description="Choose from top local liquor stores and restaurants."
            />
            <StepCard 
              number="3"
              title="Order & Pay"
              description="Secure payment and real-time order tracking."
            />
            <StepCard 
              number="4"
              title="Enjoy"
              description="Fast delivery to your door. Sip, eat, and relax."
            />
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20 bg-primary text-white">
        <div className="max-w-4xl mx-auto px-4 text-center">
          <h2 className="text-3xl md:text-4xl font-bold mb-8">Ready for the weekend?</h2>
          <p className="text-xl opacity-90 mb-10">
            Download Queless today and get R50 off your first alcohol or food order.
          </p>
          <button className="bg-white text-primary px-8 py-4 rounded-full font-bold text-lg hover:bg-gray-100 transition-colors shadow-lg">
            Get Started
          </button>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-dark text-white py-12">
        <div className="max-w-7xl mx-auto px-4">
          <div className="grid md:grid-cols-4 gap-8 mb-8">
            <div className="col-span-1 md:col-span-2">
              <span className="text-2xl font-bold text-secondary mb-4 block">Queless</span>
              <p className="text-gray-400 max-w-xs">
                South Africa's premier alcohol and food delivery service. 
                Drink responsibly.
              </p>
            </div>
            <div>
              <h3 className="font-bold mb-4">Company</h3>
              <ul className="space-y-2 text-gray-400">
                <li><a href="#" className="hover:text-white">About Us</a></li>
                <li><a href="#" className="hover:text-white">Careers</a></li>
                <li>
                  <button 
                    onClick={() => setIsPartnerModalOpen(true)}
                    className="hover:text-white text-left focus:outline-none"
                  >
                    Become a Partner
                  </button>
                </li>
              </ul>
            </div>
            <div>
              <h3 className="font-bold mb-4">Support</h3>
              <ul className="space-y-2 text-gray-400">
                <li><a href="#" className="hover:text-white">Help Center</a></li>
                <li><a href="#" className="hover:text-white">Terms of Service</a></li>
                <li><a href="#" className="hover:text-white">Privacy Policy</a></li>
              </ul>
            </div>
          </div>
          <div className="border-t border-gray-800 pt-8 text-center text-gray-500">
            <p>&copy; {new Date().getFullYear()} Queless South Africa. All rights reserved.</p>
          </div>
        </div>
      </footer>

      {/* Partner Modal */}
      <AnimatePresence>
        {isPartnerModalOpen && (
          <PartnerModal onClose={() => setIsPartnerModalOpen(false)} />
        )}
      </AnimatePresence>
    </div>
  );
}

function FeatureCard({ icon, title, description }: { icon: React.ReactNode, title: string, description: string }) {
  return (
    <div className="p-8 rounded-2xl bg-gray-50 border border-gray-100 hover:shadow-lg transition-shadow">
      <div className="mb-6 bg-white w-16 h-16 rounded-2xl flex items-center justify-center shadow-sm">
        {icon}
      </div>
      <h3 className="text-xl font-bold mb-3">{title}</h3>
      <p className="text-gray-600 leading-relaxed">{description}</p>
    </div>
  );
}

function StepCard({ number, title, description }: { number: string, title: string, description: string }) {
  return (
    <div className="text-center p-6 relative">
      <div className="w-12 h-12 bg-secondary/10 text-secondary rounded-full flex items-center justify-center text-xl font-bold mx-auto mb-4">
        {number}
      </div>
      <h3 className="text-xl font-bold mb-2">{title}</h3>
      <p className="text-gray-600">{description}</p>
    </div>
  );
}

function PartnerModal({ onClose }: { onClose: () => void }) {
  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // In the future, this will connect to Supabase
    console.log("Partner form submitted");
    alert("Thanks for your interest! We'll be in touch soon.");
    onClose();
  };

  return (
    <motion.div 
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm"
      onClick={onClose}
    >
      <motion.div 
        initial={{ scale: 0.95, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        exit={{ scale: 0.95, opacity: 0 }}
        onClick={(e) => e.stopPropagation()}
        className="bg-white rounded-3xl w-full max-w-lg p-8 shadow-2xl overflow-y-auto max-h-[90vh]"
      >
        <div className="flex justify-between items-center mb-6">
          <div>
            <h2 className="text-2xl font-bold text-primary">Become a Partner</h2>
            <p className="text-gray-500 text-sm mt-1">Join the Queless network today</p>
          </div>
          <button onClick={onClose} className="p-2 hover:bg-gray-100 rounded-full transition-colors">
            <X size={24} className="text-gray-500" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Business Name</label>
            <div className="relative">
              <Store className="absolute left-3 top-3 text-gray-400" size={20} />
              <input 
                type="text" 
                required 
                className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-secondary/50 focus:border-secondary transition-all"
                placeholder="e.g. Joe's Burgers / Sandton Liquors"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Business Type</label>
            <select className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-secondary/50 focus:border-secondary transition-all">
              <option>Restaurant / Fast Food</option>
              <option>Liquor Store</option>
              <option>Grocery Store</option>
              <option>Other</option>
            </select>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Contact Person</label>
              <input 
                type="text" 
                required
                className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-secondary/50 focus:border-secondary transition-all"
                placeholder="Name"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Phone Number</label>
              <input 
                type="tel" 
                required
                className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-secondary/50 focus:border-secondary transition-all"
                placeholder="082 123 4567"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Email Address</label>
            <input 
              type="email" 
              required
              className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-secondary/50 focus:border-secondary transition-all"
              placeholder="partner@business.co.za"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">City / Area</label>
            <div className="relative">
              <MapPin className="absolute left-3 top-3 text-gray-400" size={20} />
              <input 
                type="text" 
                required
                className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-secondary/50 focus:border-secondary transition-all"
                placeholder="e.g. Cape Town City Bowl"
              />
            </div>
          </div>

          <button 
            type="submit" 
            className="w-full bg-secondary hover:bg-green-600 text-white font-bold py-4 rounded-xl shadow-lg shadow-secondary/20 transition-all transform hover:scale-[1.02] mt-2"
          >
            Submit Application
          </button>
        </form>
      </motion.div>
    </motion.div>
  );
}

export default App;
