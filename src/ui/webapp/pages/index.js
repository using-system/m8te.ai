import Head from 'next/head';
import dynamic from 'next/dynamic';
import Layout from '../components/Layout';
import Toolbox from '../components/Toolbox';

// Chargement dynamique de la carte pour éviter les problèmes liés au SSR
const Map = dynamic(() => import('../components/Map'), { ssr: false });

export default function Home() {
  return (
    <Layout>
      <Head>
        <title>Accueil | co.bike</title>
        <meta name="description" content="Co.Bike - Roulez en sécurité et signalez les incivilités" />
      </Head>
      <div style={{ height: '70vh' }}>
        <Map />
      </div>
      <Toolbox />
    </Layout>
  );
}
