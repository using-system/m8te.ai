export async function getServerSideProps(context) {
    context.res.setHeader('Content-Type', 'application/json');
    context.res.statusCode = 200;
    context.res.end(JSON.stringify({ status: 'OK' }));
    return { props: {} };
}

export default function Health() {
    return null;
}