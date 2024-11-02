import { useState, useEffect } from 'react';
import { MapContainer, TileLayer, ZoomControl, Marker, Popup, useMap } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';

// Icone personnalisée pour le marqueur
const userIcon = new L.Icon({
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
  shadowSize: [41, 41]
});

// Composant pour centrer la carte sur la position de l'utilisateur
function CenterMap({ position }) {
  const map = useMap();
  useEffect(() => {
    if (position) {
      map.setView(position, map.getZoom());
    }
  }, [position, map]);
  return null;
}

export default function Map() {
  const [position, setPosition] = useState([48.8566, 2.3522]); // Position par défaut (Paris)
  const maxZoom = 18; // Zoom maximal

  useEffect(() => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (pos) => {
          const { latitude, longitude } = pos.coords;
          setPosition([latitude, longitude]);
        },
        (err) => {
          console.error('Erreur lors de l\'obtention de la position:', err);
        }
      );
    }
  }, []);

  return (
    <MapContainer 
      center={position} 
      zoom={maxZoom} 
      style={{ height: '100%', width: '100%', filter: 'invert(90%) hue-rotate(180deg)' }} // Applique un filtre sombre
      zoomControl={false}
    >
      <TileLayer
        url="https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png"
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors, <a href="https://cyclosm.org/">CyclOSM</a>'
      />
      <ZoomControl position="topright" />
      <Marker position={position} icon={userIcon}>
        <Popup>Vous êtes ici</Popup>
      </Marker>
      <CenterMap position={position} />
    </MapContainer>
  );
}
