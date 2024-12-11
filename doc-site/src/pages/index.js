import Link from '@docusaurus/Link';
import Heading from '@theme/Heading';
import Layout from '@theme/Layout';
import styles from './index.module.css';

export default function Home() {
    return (
        <Layout description={``}>
            <main className={styles.main}>
                <h1 className={styles.h1}>Revali</h1>
                <div className={styles.layout}>
                    <GettingStarted />
                    <SellingPoints />
                </div>
            </main>
        </Layout>
    );
}


function GettingStarted() {
    return (
        <section id="getting-started" className={styles.gettingStarted}>
            <img alt="Revali Preview" className={styles.previewImage} src={require('@site/static/img/preview.gif').default} />
            <CTA className={styles.cta} />
        </section>
    );
}

function SellingPoints() {
    const points = [
    {
            title: 'Highly Extendable',
            src: require('@site/static/img/extendable.png').default,
            description:
                'Easily extend capabilities using community packages or by creating your own.',
        },
        {
            title: 'Rapid Development',
            src: require('@site/static/img/rapid-development.png').default,
            description:
                'Quickly develop endpoints with minimal setup and configuration.',
        },
        {
            title: 'Powered by Dart',
            src: require('@site/static/img/dart.png').default,
            description:
                'Leverage Dart for type safety, object-oriented programming, and high performance.',
        },
    ];

    return (
        <section id="selling-points" className={styles.sellingPoints}>
            {points.map((props, index) => (
                <SellingPoint key={index} {...props} />
            ))}
        </section>
    );
}

function SellingPoint({ src, title, description }) {

    return (
        <div className={styles.sellingPoint}>
            <img alt={title} src={src} />
            <Heading as="h2">{title}</Heading>
            <p>{description}</p>
        </div>
    );
}

function CTA() {
    return (
        <div className={styles.cta}>
            <Link className="button button--primary button--lg" to="/revali">
                Get Started
            </Link>
        </div>
    );
}
