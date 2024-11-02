import HeaderMenu from './HeaderMenu';
import Footer from './Footer';

export default function Layout({ children }) {
  return (
    <div style={{ backgroundColor: '#111', color: '#ddd', minHeight: '100vh' }}>
      <header style={{ display: 'flex', justifyContent: 'flex-start', padding: '10px' }}>
        <HeaderMenu />
      </header>
      <main>
        {children}
      </main>
      <Footer />
    </div>
  );
}
