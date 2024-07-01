FROM ghcr.io/dependabot/dependabot-updater-core

USER dependabot
COPY --chown=dependabot:dependabot sbt $DEPENDABOT_HOME/sbt
COPY --chown=dependabot:dependabot common $DEPENDABOT_HOME/common
COPY --chown=dependabot:dependabot updater $DEPENDABOT_HOME/dependabot-updater
