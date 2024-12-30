import Head from 'next/head';
import dynamic from 'next/dynamic';
import Layout from '../components/Layout';

// Chargement dynamique de la carte pour éviter les problèmes liés au SSR
const App = dynamic(() => import('../components/App'), { ssr: false });

export default function Home() {
  return (
    <Layout>
      <Head>
        <title>Accueil | co.bike</title>
        <meta name="description" content="Co.Bike - Roulez en sécurité et signalez les incivilités" />
      </Head>
      <div style={{ height: '70vh' }}>
        <App />
      </div>
    </Layout>
  );
}
