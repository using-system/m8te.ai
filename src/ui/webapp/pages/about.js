import Head from 'next/head';
import Layout from '../components/Layout';

export default function About() {
  return (
    <Layout>
      <Head>
        <title>À propos | co.bike</title>
        <meta name="description" content="À propos de Co.Bike - Roulez en sécurité et signalez les incivilités" />
      </Head>
      <h1>À propos de Co.Bike</h1>
      <p>
        <strong>Co.Bike</strong> : l'application pour rouler en sécurité et signaler les incivilités, incidents ou dangers. 
        <br />
        <br />
        <strong>Co</strong> pour <em>COhabitation</em>, <em>COopération</em>, <em>COmmunauté</em>.
      </p>
      <p>
        L'application est en cours de développement. Suivez son avancement sur le <a href='https://github.com/using-system/co.bike' target='_blank'>GitHub officiel co.bike</a>.
      </p>
      <p>
        En mémoire à Paul Varry.
      </p>
    </Layout>
  );
}
