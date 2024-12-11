import Link from '@docusaurus/Link';
import Heading from '@theme/Heading';
import Layout from '@theme/Layout';
import styles from './index.module.css';

export default function Home() {
    return (
        <Layout description={``}>
            <main className={styles.main}>
                <h1 className={styles.h1}>Revali</h1>
                <Logo />
                <div className={styles.layout}>
                    <GettingStarted />
                    <SellingPoints />
                </div>
            </main>
        </Layout>
    );
}

function Logo() {
    return (
        <div className={styles.logo}>
            <p title="logo" className={styles.logoImage}>Revali</p>
        </div>
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
            title: 'Rapid Development',
            Svg: require('@site/static/img/rapid-development.svg').default,
            description:
                'Quickly develop endpoints with minimal setup and configuration.',
        },
        {
            title: 'Highly Extendable',
            Svg: require('@site/static/img/extendable.svg').default,
            description:
                'Easily extend capabilities using community packages or by creating your own.',
        },
        {
            title: 'Powered by Dart',
            Svg: require('@site/static/img/dart.svg').default,
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

function SellingPoint({ Svg, title, description }) {
    return (
        <div className={styles.sellingPoint}>
            <Svg role="img" />
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
