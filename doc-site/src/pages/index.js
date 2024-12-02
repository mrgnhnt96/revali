import Link from '@docusaurus/Link';
import FullLogoSvg from '@site/static/img/full_logo.svg';
import HeroImageSvg from '@site/static/img/hero_image.svg';
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
            <FullLogoSvg title="logo" role="img" className={styles.logoImage} />
        </div>
    );
}

function GettingStarted() {
    return (
        <section id="getting-started" className={styles.gettingStarted}>
            <HeroImageSvg
                title="Revali Usage Example"
                className={styles.heroImage}
            />
            <CTA />
        </section>
    );
}

function SellingPoints() {
    const points = [
        {
            title: 'Fast Dev Cycle',
            Svg: require('@site/static/img/fast.svg').default,
            description: 'Develop endpoints quickly with minimum setup',
        },
        {
            title: 'Extendable',
            Svg: require('@site/static/img/building-blocks.svg').default,
            description:
                'Extend the capabilities by using community packages or create your own',
        },
        {
            title: 'Build on Dart',
            Svg: require('@site/static/img/dart.svg').default,
            description: 'Type safe, Object Oriented, and fast',
        },
    ];

    return (
        <section id="selling-points" className={styles.sellingPoints}>
            {points.map((props, idx) => (
                <SellingPoint key={idx} {...props} />
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
