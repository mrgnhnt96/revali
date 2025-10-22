import Link from "@docusaurus/Link";
import Heading from "@theme/Heading";
import Layout from "@theme/Layout";
import styles from "./index.module.css";

export default function Home() {
  return (
    <Layout description="A modern, fast, and powerful Dart API framework">
      <main className={styles.main}>
        <HeroSection />
        <FeaturesSection />
        <CodeExampleSection />
        <CTASection />
      </main>
    </Layout>
  );
}

function HeroSection() {
  return (
    <section className={styles.hero}>
      <div className={styles.heroContent}>
        <div className={styles.heroText}>
          <Heading as="h1" className={styles.heroTitle}>
            Build Powerful APIs with{" "}
            <span className={styles.highlight}>Dart</span>
          </Heading>
          <p className={styles.heroDescription}>
            Revali is a modern, fast, and powerful Dart API framework that makes
            building robust web services effortless. Get type safety, excellent
            performance, and rapid development out of the box.
          </p>
          <div className={styles.heroButtons}>
            <Link
              className={`button button--primary button--lg ${styles.primaryButton}`}
              to="/revali"
            >
              Get Started
            </Link>
            <Link
              className={`button button--secondary button--lg ${styles.secondaryButton}`}
              to="https://github.com/mrgnhnt96/revali"
            >
              View on GitHub
            </Link>
          </div>
        </div>
        <div className={styles.heroVisual}>
          <img
            alt="Revali Framework Preview"
            className={styles.heroImage}
            src={require("@site/static/img/preview.gif").default}
          />
        </div>
      </div>
    </section>
  );
}

function FeaturesSection() {
  const features = [
    {
      title: "Highly Extendable",
      icon: require("@site/static/img/extendable.png").default,
      description:
        "Easily extend capabilities using community packages or by creating your own custom constructs.",
      color: "#4F46E5",
    },
    {
      title: "Rapid Development",
      icon: require("@site/static/img/rapid-development.png").default,
      description:
        "Quickly develop endpoints with minimal setup and configuration. Focus on your business logic.",
      color: "#059669",
    },
    {
      title: "Powered by Dart",
      icon: require("@site/static/img/dart.png").default,
      description:
        "Leverage Dart for type safety, object-oriented programming, and high performance.",
      color: "#DC2626",
    },
  ];

  return (
    <section className={styles.features}>
      <div className={styles.container}>
        <div className={styles.sectionHeader}>
          <Heading as="h2" className={styles.sectionTitle}>
            Why Choose Revali?
          </Heading>
          <p className={styles.sectionDescription}>
            Built for developers who want to create exceptional APIs without
            compromise
          </p>
        </div>
        <div className={styles.featuresGrid}>
          {features.map((feature, index) => (
            <FeatureCard key={index} {...feature} />
          ))}
        </div>
      </div>
    </section>
  );
}

function FeatureCard({ icon, title, description, color }) {
  return (
    <div className={styles.featureCard}>
      <div
        className={styles.featureIcon}
        style={{ backgroundColor: `${color}20` }}
      >
        <img alt={title} src={icon} />
      </div>
      <Heading as="h3" className={styles.featureTitle}>
        {title}
      </Heading>
      <p className={styles.featureDescription}>{description}</p>
    </div>
  );
}

function CodeExampleSection() {
  return (
    <section className={styles.codeExample}>
      <div className={styles.container}>
        <div className={styles.codeContent}>
          <div className={styles.codeText}>
            <Heading as="h2" className={styles.codeTitle}>
              Simple, Powerful, Type-Safe
            </Heading>
            <p className={styles.codeDescription}>
              Create robust APIs with minimal boilerplate. Revali's intuitive
              API design makes complex operations simple and type-safe.
            </p>
            <Link
              className={`button button--primary ${styles.codeButton}`}
              to="/revali/getting-started"
            >
              Learn More
            </Link>
          </div>
          <div className={styles.codeBlock}>
            <pre className={styles.codePre}>
              <code className={styles.codeCode}>
                {`// Create a simple API endpoint
@Route('/api/users')
class UserController {
  @Get('/')
  Future<List<User>> getUsers() async {
    return await userService.getAllUsers();
  }
  
  @Post('/')
  Future<User> createUser(@Body() User user) async {
    return await userService.createUser(user);
  }
}`}
              </code>
            </pre>
          </div>
        </div>
      </div>
    </section>
  );
}

function CTASection() {
  return (
    <section className={styles.ctaSection}>
      <div className={styles.container}>
        <div className={styles.ctaContent}>
          <Heading as="h2" className={styles.ctaTitle}>
            Ready to Build Something Amazing?
          </Heading>
          <p className={styles.ctaDescription}>
            Join the growing community of developers building powerful APIs with
            Revali.
          </p>
          <div className={styles.ctaButtons}>
            <Link
              className={`button button--primary button--lg ${styles.ctaPrimary}`}
              to="/revali"
            >
              Start Building
            </Link>
            <Link
              className={`button button--outline button--lg ${styles.ctaSecondary}`}
              to="/constructs"
            >
              Explore Constructs
            </Link>
          </div>
        </div>
      </div>
    </section>
  );
}
