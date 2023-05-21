import React, { FC, useState, useEffect } from 'react'
import { CognitoIdentityClient, GetCredentialsForIdentityCommand } from '@aws-sdk/client-cognito-identity'
import { AppConfigDataClient, StartConfigurationSessionCommand, GetLatestConfigurationCommand } from '@aws-sdk/client-appconfigdata'

const TOKEN_ENDPOINT = 'http://localhost:8080/token'

const APP_CONFIG_APPLICATION = 'my-appconfig-application'
const APP_CONFIG_PROFILE = 'my-appconfig-configuration-profile'
const APP_CONFIG_ENVIRONMENT = 'Beta'

interface TokenResponse {
	region: string;
	identityPoolId: string;
	identityId: string;
	loginProvider: string;
	token: string;
}

const useAppConfigThroughCognito = (): { configData: string, error: Error | undefined, isLoading: boolean } => {

	const [configData, setConfigData] = useState<string>('')
	const [error, setError] = useState<Error | undefined>(undefined)
	const [isLoading, setIsLoading] = useState<boolean>(false)

	useEffect(() => {

		let setTimeoutId: NodeJS.Timeout | undefined = undefined
		const fetchToken = async () => {

			setIsLoading(true)

			try {
				const apiResponse = await fetch(TOKEN_ENDPOINT)
				const data = await apiResponse.json() as TokenResponse

				const cognitoClient = new CognitoIdentityClient({ region: data.region })
				const getCredentialsCommand = new GetCredentialsForIdentityCommand({
					IdentityId: data.identityId,
					Logins: {
						'cognito-identity.amazonaws.com': data.token
					},
				})
				const awsResponse = await cognitoClient.send(getCredentialsCommand)


				const appConfigClient = new AppConfigDataClient({
					region: data.region,
					credentials: {
						accessKeyId: awsResponse.Credentials?.AccessKeyId as string,
						secretAccessKey: awsResponse.Credentials?.SecretKey as string,
						sessionToken: awsResponse.Credentials?.SessionToken as string,
					}
				})

				const startAppConfigSessionCommand = new StartConfigurationSessionCommand({
					ApplicationIdentifier: APP_CONFIG_APPLICATION,
					ConfigurationProfileIdentifier: APP_CONFIG_PROFILE,
					EnvironmentIdentifier: APP_CONFIG_ENVIRONMENT,
				})

				const startSessionResponse = await appConfigClient.send(startAppConfigSessionCommand)

				const pollConfiguration = async (token: string | undefined): Promise<void> => {

					const appConfigCommand = new GetLatestConfigurationCommand({
						ConfigurationToken: token,
					})

					const appConfigResponse = await appConfigClient.send(appConfigCommand)

					if (!appConfigResponse.NextPollIntervalInSeconds || !appConfigResponse.NextPollConfigurationToken) {
						throw Error('Invalid response from AppConfig')
					}

					if (appConfigResponse.Configuration) {
						let content = ''
						for (let i = 0; i < appConfigResponse.Configuration.length; i++) {
							content += String.fromCharCode(appConfigResponse.Configuration[i])
						}

						if (content) {
							setConfigData(content)
						} else {
							console.log('Configuration is empty (Not changed)')
						}
					}

					console.log('Next poll in', appConfigResponse.NextPollIntervalInSeconds, 'seconds')

					setTimeoutId = setTimeout(() => {
						if (setTimeoutId) {
							clearTimeout(setTimeoutId)
						}
						pollConfiguration(appConfigResponse.NextPollConfigurationToken)
					}, appConfigResponse.NextPollIntervalInSeconds * 1000)

				}

				await pollConfiguration(startSessionResponse.InitialConfigurationToken)



			} catch (error) {
				setError(error as Error)
			}
			setIsLoading(false)
		}
		fetchToken()

		return () => {
			if (setTimeoutId) {
				clearTimeout(setTimeoutId)
			}
		}
	}, [])

	return { configData, error, isLoading }
}


export const Config: FC = () => {

	const { configData, error, isLoading } = useAppConfigThroughCognito()

	return (
		<>
			<>{isLoading ? <p>Loading...</p> :
				<>
					{error ? <p>{error.message}</p> : <pre>{configData}</pre>}
				</>
			}</>
		</>
	)
}