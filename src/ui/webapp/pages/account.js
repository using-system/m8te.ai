import Head from 'next/head';
import Layout from '../components/Layout';
import Toolbox from '../components/Toolbox';

export default function Account() {
  return (
    <Layout>
      <Head>
        <title>Mon Compte | co.bike</title>
        <meta name="description" content="Mon Compte - Co.Bike" />
      </Head>
      <div style={{ padding: '20px', textAlign: 'center' }}>
        <h1>Mon Compte</h1>
        <p>Bientôt ici votre espace personnel</p>
      </div>
      <Toolbox />
    </Layout>
  );
}
