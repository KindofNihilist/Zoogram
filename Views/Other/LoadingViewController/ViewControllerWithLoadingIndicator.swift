//
//  ViewControllerWithLoadingIndicator.swift
//  Zoogram
//
//  Created by Artem Dolbiiev on 10.01.2024.
//

import UIKit

class ViewControllerWithLoadingIndicator: UIViewController {

    var reloadAction: (() -> Void)?

    var isMainViewVisible: Bool = false

    var mainView: UIView? {
        didSet {
            mainView?.alpha = 0
        }
    }

    private var isShowingLoadingError: Bool = false

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView(style: .medium)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        return indicatorView
    }()

    private lazy var loadingErrorNotificationView: LoadingErrorView = {
        let view =  LoadingErrorView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        return view
    }()

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLoadingIndicator()
    }

    private func setupLoadingIndicator() {
        view.addSubviews(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -49),
            loadingIndicator.heightAnchor.constraint(equalToConstant: 60),
            loadingIndicator.widthAnchor.constraint(equalToConstant: 60)
        ])
        loadingIndicator.startAnimating()
        view.bringSubviewToFront(loadingIndicator)
    }

    private func removeLoadingIndicator() {
        self.loadingIndicator.stopAnimating()
        self.loadingIndicator.removeFromSuperview()
    }

    func showMainView(completion: @escaping () -> Void = {}) {
        guard let mainView = self.mainView, mainView.alpha == 0 else {
            return
        }

        UIView.animateKeyframes(withDuration: 0.7, delay: 0) {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                self.loadingIndicator.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
                self.loadingIndicator.alpha = 0
            }
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                mainView.alpha = 1
            }
        } completion: { _ in
            self.isMainViewVisible = true
            self.removeLoadingIndicator()
            completion()
        }
    }

    func showLoadingErrorNotification(text: String) {
        guard self.isShowingLoadingError == false else { return }
        self.removeLoadingIndicator()
        loadingErrorNotificationView.setDescriptionLabelText(text)
        self.loadingErrorNotificationView.alpha = 1
        view.addSubview(loadingErrorNotificationView)
        NSLayoutConstraint.activate([
            loadingErrorNotificationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingErrorNotificationView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -49),
            loadingErrorNotificationView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -60),
            loadingErrorNotificationView.heightAnchor.constraint(equalToConstant: 60)
        ])
        self.isShowingLoadingError = true
    }

    private func hideReloadButton() {
        UIView.animate(withDuration: 0.2) {
            self.loadingErrorNotificationView.alpha = 0
        } completion: { _ in
            self.loadingErrorNotificationView.removeFromSuperview()
        }
    }

    func removeLoadingErrorNotificationIfDisplayed() {
        if isShowingLoadingError {
            self.loadingErrorNotificationView.removeFromSuperview()
        }
    }
}

extension ViewControllerWithLoadingIndicator: LoadingErrorViewDelegate {
    func didTapReloadButton() {
        self.hideReloadButton()
        self.isShowingLoadingError = false
        self.setupLoadingIndicator()
        self.reloadAction?()
    }
}
