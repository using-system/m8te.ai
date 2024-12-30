export default function Layout({ children }) {
  return (
    <div style={{ backgroundColor: '#111', color: '#ddd', minHeight: '100vh' }}>
      <main>
        {children}
      </main>
    </div>
  );
}
