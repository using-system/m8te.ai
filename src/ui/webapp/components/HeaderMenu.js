import { useState, useEffect, useRef } from 'react';

export default function HeaderMenu() {
  const [isOpen, setIsOpen] = useState(false);
  const menuRef = useRef(null);

  const toggleMenu = () => {
    setIsOpen(!isOpen);
  };

  const handleClickOutside = (event) => {
    if (menuRef.current && !menuRef.current.contains(event.target)) {
      setIsOpen(false);
    }
  };

  useEffect(() => {
    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    } else {
      document.removeEventListener('mousedown', handleClickOutside);
    }

    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [isOpen]);

  return (
    <div style={{ zIndex: 1000 }}>
      <button 
        onClick={toggleMenu} 
        style={{ 
          background: 'none', 
          border: 'none', 
          cursor: 'pointer', 
          color: '#ddd', 
          fontSize: '24px' 
        }}
      >
        ☰ 
      </button>
      {isOpen && (
        <div 
          ref={menuRef}
          style={{
            position: 'fixed',
            top: 0,
            left: 0,
            height: '100%',
            width: '250px',
            background: '#333',
            color: '#ddd',
            padding: '20px',
            boxShadow: '2px 0 8px rgba(0, 0, 0, 0.3)',
            zIndex: 1001,
            transition: 'transform 0.3s ease-in-out',
            transform: isOpen ? 'translateX(0)' : 'translateX(-100%)'
          }}
        >
          <ul style={{ listStyleType: 'none', padding: 0, margin: 0 }}>
            <li style={{ display: 'flex', alignItems: 'center', marginBottom: '20px' }}>
              {/* Icône de vélo simplifiée */}
              <svg width="24" height="24" fill="currentColor" xmlns="http://www.w3.org/2000/svg" style={{ marginRight: '10px' }}>
                <circle cx="6" cy="17" r="3" />
                <circle cx="18" cy="17" r="3" />
                <path d="M6 17h4l4-6h4M10 17l3-4" stroke="#ddd" strokeWidth="2" fill="none" />
              </svg>
              <a href="/" style={{ color: '#ddd', textDecoration: 'none' }}>App</a>
            </li>
            <li style={{ display: 'flex', alignItems: 'center', marginBottom: '20px' }}>
              <svg width="20" height="20" fill="currentColor" xmlns="http://www.w3.org/2000/svg" style={{ marginRight: '10px' }}>
                <path d="M12 2a10 10 0 100 20 10 10 0 000-20zm-1 15h-2v-2h2v2zm1-4h-3V7h3v6z" />
              </svg>
              <a href="/about" style={{ color: '#ddd', textDecoration: 'none' }}>À propos</a>
            </li>
          </ul>
        </div>
      )}
    </div>
  );
}
