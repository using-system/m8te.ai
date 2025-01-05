export default function Footer() {
  const currentYear = new Date().getFullYear(); // Obtient l'année en cours

  return (
    <footer style={{ textAlign: 'center', padding: '10px', background: '#222', color: '#ddd', borderTop: '1px solid #444' }}>
      <p>&copy; {currentYear} co.bike.</p>
    </footer>
  );
}
